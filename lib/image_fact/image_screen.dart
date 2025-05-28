import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fact_pulse/authentication/authentication_bloc/authentication_bloc.dart';
import 'package:fact_pulse/authentication/authentication_enums.dart';
import 'package:fact_pulse/core/utils/app_extensions.dart';
import 'package:fact_pulse/core/utils/widgets/custom_bottom_sheet.dart';
import 'package:fact_pulse/core/widgets/fact_check_app_bar.dart';
import 'package:fact_pulse/models/perplexity_response_model.dart';
import 'package:fact_pulse/debate/prompts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:perplexity_flutter/perplexity_flutter.dart';

class ImageReportScreen extends StatefulWidget {
  final String imageId;
  final String topic;
  
  const ImageReportScreen({
    super.key, 
    required this.imageId, 
    required this.topic,
  });

  @override
  State<ImageReportScreen> createState() => _ImageReportScreenState();
}

class _ImageReportScreenState extends State<ImageReportScreen> {
  late PerplexityClient _client;
  late final String uid;
  int _currentImageIndex = 0;
  bool _isAnalyzing = false;
  List<String> _imageData = []; // For URL images stored in Firestore
  List<XFile> _localImages = []; // For local images not stored in Firestore
  final _isLoadingController = StreamController<bool>.broadcast();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthenticationBloc>().state;
    if (authState.status == AuthenticationStatus.authenticated) {
      uid = authState.user.id;
    }
    _client = PerplexityClient(apiKey: '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');
    
    // Once user & widget.imageId are ready, do:
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupImageDoc());
  }

  Future<void> _setupImageDoc() async {
    final authState = context.read<AuthenticationBloc>().state;
    if (authState.status != AuthenticationStatus.authenticated) return;
    final uid = authState.user.id;
    final imageDoc = _firestore
        .collection('users')
        .doc(uid)
        .collection('images')
        .doc(widget.imageId);

    final snapshot = await imageDoc.get();
    if (!snapshot.exists) {
      // First time: seed all fields including an empty response
      await imageDoc.set({
        'topic': widget.topic,
        'createdAt': FieldValue.serverTimestamp(),
        'response': '',
        'complete': false,
        'imageData': _imageData,
      });
    } else {
      // Already exists: only ensure topic is up to date
      await imageDoc.set({
        'lastOpenedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Load existing image data if available
      final data = snapshot.data();
      if (data != null && data['imageData'] is List) {
        setState(() {
          _imageData = List<String>.from(data['imageData']);
        });
      }
    }
  }

  // Pick local images (not stored in Firestore)
  Future<void> _pickLocalImages() async {
    try {
      _isLoadingController.add(true);
      final pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _localImages.addAll(pickedFiles);
          _currentImageIndex = 0; // Reset to first image
        });
        
        // Analyze the first local image if no images were previously available
        if (_localImages.length == pickedFiles.length && _imageData.isEmpty) {
          final pickedFile = _localImages.first;
          final bytes = kIsWeb
              ? await pickedFile.readAsBytes()
              : await File(pickedFile.path).readAsBytes();
          final base64String = base64Encode(bytes);
          await _analyzeImage(base64String);
        }
      }
    } catch (e) {
      debugPrint('Error picking local images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: ${e.toString()}')),
      );
    } finally {
      _isLoadingController.add(false);
    }
  }

  // Add URL images (stored in Firestore)
  Future<void> _addUrlImage(String imageUrl) async {
    try {
      _isLoadingController.add(true);
      
      setState(() {
        _imageData.add(imageUrl);
        _currentImageIndex = _localImages.length; // Show the first URL image
      });
      
      // Update Firestore with new URL images
      final authState = context.read<AuthenticationBloc>().state;
      if (authState.status == AuthenticationStatus.authenticated) {
        final uid = authState.user.id;
        final imageDoc = _firestore
            .collection('users')
            .doc(uid)
            .collection('images')
            .doc(widget.imageId);
        
        await imageDoc.update({
          'imageData': _imageData,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Analyze the URL image
      await _analyzeImage(imageUrl);
    } catch (e) {
      print('Error adding URL image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding URL image: ${e.toString()}')),
      );
    } finally {
      _isLoadingController.add(false);
    }
  }

  // Show dialog to add URL image
  void _showAddUrlDialog() {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Image URL'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'Image URL',
            hintText: 'https://example.com/image.jpg',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(context);
                _addUrlImage(url);
              }
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeImage(String imageSource) async {
    if (_isAnalyzing) return;
    
    setState(() {
      _isAnalyzing = true;
    });
    
    try {
      final authState = context.read<AuthenticationBloc>().state;
      if (authState.status != AuthenticationStatus.authenticated) return;
      final uid = authState.user.id;

      final imageDoc = _firestore
          .collection('users')
          .doc(uid)
          .collection('images')
          .doc(widget.imageId);

      // Use the loadImageSystemPrompt from prompts.dart
      final systemPrompt = loadImageSystemPrompt(topic: widget.topic);
      
      // Create a prompt that describes the image
      final imagePrompt = "Analyze this image and identify any factual claims present. The image is related to the topic: ${widget.topic}";
      
      // Determine if the imageSource is a URL or base64
      List<String> urlList = [];
      if (imageSource.startsWith('http')) {
        // It's a URL
        urlList.add(imageSource);
      } else {
        // It's a base64 string, we need to convert it to a data URL
        final dataUrl = 'data:image/jpeg;base64,$imageSource';
        urlList.add(dataUrl);
      }
      
      final request = ChatRequestModel.defaultImageRequest(
        urlList: urlList,
        systemPrompt: systemPrompt,
        imagePrompt: imagePrompt,
        stream: false,
        model: PerplexityModel.sonar,
      );

      final response = await _client.sendMessage(requestModel: request);
      final decoded = jsonDecode(response.content);
      final model = PerplexityResponseModel.fromJson(decoded);

      await imageDoc.set({
        'response': imagePrompt,
        'complete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Batch-write each claim into its own doc
      final batch = _firestore.batch();
      final claimsCol = imageDoc.collection('claims');
      for (final c in model.claims ?? []) {
        final doc = claimsCol.doc();
        batch.set(doc, {
          'claim': c.claim,
          'rating': c.rating,
          'explanation': c.explanation,
          'sources': c.sources,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image analyzed successfully!')),
      );
    } catch (e) {
      debugPrint('Error analyzing image: $e');
      // Optional: record error on parent doc
      final authState = context.read<AuthenticationBloc>().state;
      if (authState.status == AuthenticationStatus.authenticated) {
        final uid = authState.user.id;
        final imageDoc = _firestore
            .collection('users')
            .doc(uid)
            .collection('images')
            .doc(widget.imageId);
        await imageDoc.set({'error': e.toString()}, SetOptions(merge: true));
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error analyzing image: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _removeLocalImage(int index) {
    if (_localImages.isEmpty || index >= _localImages.length) return;
    
    setState(() {
      _localImages.removeAt(index);
      if (_currentImageIndex >= _localImages.length) {
        _currentImageIndex = _localImages.isEmpty ? 0 : _localImages.length - 1;
      }
    });
  }

  void _removeUrlImage(int index) {
    if (_imageData.isEmpty || index >= _imageData.length) return;
    
    final actualIndex = index - _localImages.length;
    if (actualIndex < 0 || actualIndex >= _imageData.length) return;
    
    setState(() {
      _imageData.removeAt(actualIndex);
      if (_currentImageIndex >= _localImages.length + _imageData.length) {
        _currentImageIndex = (_localImages.length + _imageData.length) - 1;
      }
    });
    
    // Update Firestore with updated images
    final authState = context.read<AuthenticationBloc>().state;
    if (authState.status == AuthenticationStatus.authenticated) {
      final uid = authState.user.id;
      final imageDoc = _firestore
          .collection('users')
          .doc(uid)
          .collection('images')
          .doc(widget.imageId);
      
      imageDoc.update({
        'imageData': _imageData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  void dispose() {
    _isLoadingController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      appBar: FactCheckAppBar(
        title: 'Image Analysis',
        subtitle: widget.topic,
        onInfoPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('About This Image Analysis'),
              content: Text('Topic: ${widget.topic}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ],
            ),
          );
        },
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceVariant.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: isSmallScreen 
                ? _buildVerticalLayout(theme)
                : _buildHorizontalLayout(theme),
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'addUrl',
            onPressed: _isAnalyzing ? null : _showAddUrlDialog,
            child: const Icon(Icons.link),
            tooltip: 'Add Image URL',
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: 'addLocal',
            onPressed: _isAnalyzing ? null : _pickLocalImages,
            child: _isAnalyzing 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.add_photo_alternate),
            tooltip: 'Add Local Images',
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalLayout(ThemeData theme) {
    return Column(
      children: [
        // Image carousel with thumbnails
        Container(
          constraints: BoxConstraints(
            maxHeight: context.height * 0.35, // Increased height to accommodate thumbnails
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: _localImages.isEmpty && _imageData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_search,
                        size: 48,
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No images yet',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text('Add Local Images'),
                            onPressed: _pickLocalImages,
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.link),
                            label: const Text('Add URL'),
                            onPressed: _showAddUrlDialog,
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildImageCarousel(theme),
                  ),
                ),
        ),
        
        const SizedBox(height: 16),
        
        // Claims list
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.fact_check,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Fact Checks',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('users')
                        .doc(uid)
                        .collection('images')
                        .doc(widget.imageId)
                        .collection('claims')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (ctx, snap) {
                      if (snap.hasError) {
                        return Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Error: ${snap.error}',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        );
                      }
                      
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final docs = snap.data!.docs;
                      
                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No fact checks yet',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add images to analyze them',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final data = docs[i].data() as Map<String, dynamic>;
                          final claim = Claims(
                            claim: data['claim'] as String?,
                            rating: data['rating'] as String?,
                            explanation: data['explanation'] as String?,
                            sources: (data['sources'] as List<dynamic>?)?.cast<String>(),
                          );
                          return _buildClaimCard(theme, claim, () {
                            CustomBottomSheet().showLinksSheet(ctx, claim.sources ?? []);
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalLayout(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image carousel with thumbnails - takes 40% of width
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: _localImages.isEmpty && _imageData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_search,
                          size: 48,
                          color: theme.colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No images yet',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add_photo_alternate),
                              label: const Text('Add Local Images'),
                              onPressed: _pickLocalImages,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.link),
                              label: const Text('Add URL'),
                              onPressed: _showAddUrlDialog,
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildImageCarousel(theme),
                    ),
                  ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Parsed claims list - takes 60% of width
        Expanded(
          flex: 6,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.fact_check,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Fact Checks',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('users')
                        .doc(uid)
                        .collection('images')
                        .doc(widget.imageId)
                        .collection('claims')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (ctx, snap) {
                      if (snap.hasError) {
                        return Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Error: ${snap.error}',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        );
                      }
                      
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final docs = snap.data!.docs;
                      
                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No fact checks yet',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add images to analyze them',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final data = docs[i].data() as Map<String, dynamic>;
                          final claim = Claims(
                            claim: data['claim'] as String?,
                            rating: data['rating'] as String?,
                            explanation: data['explanation'] as String?,
                            sources: (data['sources'] as List<dynamic>?)?.cast<String>(),
                          );
                          return _buildClaimCard(theme, claim, () {
                            CustomBottomSheet().showLinksSheet(ctx, claim.sources ?? []);
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageCarousel(ThemeData theme) {
    // Calculate total number of images (local + URL)
    final totalImages = _localImages.length + _imageData.length;
    
    return Column(
      children: [
        // Main image display
        Expanded(
          child: Stack(
            children: [
              // Main image
              Center(
                child: _currentImageIndex < _localImages.length
                    ? kIsWeb
                        ? FutureBuilder<Uint8List>(
                            future: _localImages[_currentImageIndex].readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text('Error loading image: ${snapshot.error}'),
                                );
                              }
                              if (!snapshot.hasData) {
                                return const Center(child: Text('No image data'));
                              }
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.contain,
                              );
                            },
                          )
                        : Image.file(
                            File(_localImages[_currentImageIndex].path),
                            fit: BoxFit.contain,
                          )
                    : Image.network(
                        _imageData[_currentImageIndex - _localImages.length],
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / 
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(color: theme.colorScheme.error),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              
              // Delete button
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onPressed: () {
                    if (_currentImageIndex < _localImages.length) {
                      _removeLocalImage(_currentImageIndex);
                    } else {
                      _removeUrlImage(_currentImageIndex);
                    }
                  },
                ),
              ),
              
              // Analyze button
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: _isAnalyzing 
                        ? const SizedBox(
                            width: 16, 
                            height: 16, 
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.search, color: Colors.white),
                  ),
                  onPressed: _isAnalyzing ? null : () async {
                    if (_currentImageIndex < _localImages.length) {
                      // Analyze local image
                      final pickedFile = _localImages[_currentImageIndex];
                      final bytes = kIsWeb
                          ? await pickedFile.readAsBytes()
                          : await File(pickedFile.path).readAsBytes();
                      final base64String = base64Encode(bytes);
                      await _analyzeImage(base64String);
                    } else {
                      // Analyze URL image
                      await _analyzeImage(_imageData[_currentImageIndex - _localImages.length]);
                    }
                  },
                ),
              ),
              
              // Image counter
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1}/$totalImages',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Thumbnail strip
        if (totalImages > 0)
          Container(
            height: 70,
            margin: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                // Add more images button
                Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.add_photo_alternate),
                              title: const Text('Add Local Images'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickLocalImages();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.link),
                              title: const Text('Add URL Image'),
                              onTap: () {
                                Navigator.pop(context);
                                _showAddUrlDialog();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Image thumbnails
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: totalImages,
                    itemBuilder: (context, index) {
                      final isSelected = index == _currentImageIndex;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        child: Container(
                          width: 60,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected 
                                  ? theme.colorScheme.primary 
                                  : theme.colorScheme.outline.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: index < _localImages.length
                                ? kIsWeb
                                    ? FutureBuilder<Uint8List>(
                                        future: _localImages[index].readAsBytes(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            );
                                          }
                                          if (snapshot.hasError || !snapshot.hasData) {
                                            return Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                color: theme.colorScheme.error,
                                                size: 20,
                                              ),
                                            );
                                          }
                                          return Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      )
                                    : Image.file(
                                        File(_localImages[index].path),
                                        fit: BoxFit.cover,
                                      )
                                : Image.network(
                                    _imageData[index - _localImages.length],
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / 
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          color: theme.colorScheme.error,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildClaimCard(ThemeData theme, Claims claim, VoidCallback onTap) {
    final rating = claim.rating ?? 'UNVERIFIABLE';
    Color bgColor;
    
    switch (rating) {
      case 'TRUE':
        bgColor = Colors.green.shade50;
        break;
      case 'FALSE':
        bgColor = Colors.red.shade50;
        break;
      case 'MISLEADING':
        bgColor = Colors.orange.shade50;
        break;
      default:
        bgColor = Colors.grey.shade50;
    }
    
    final radius = BorderRadius.circular(12);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRatingColor(rating).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      rating,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getRatingColor(rating),
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.link, size: 18),
                    onPressed: onTap,
                    tooltip: 'View Sources',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                claim.claim ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                claim.explanation ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRatingColor(String rating) {
    switch (rating) {
      case 'TRUE':
        return Colors.green;
      case 'FALSE':
        return Colors.red;
      case 'MISLEADING':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
