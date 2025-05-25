class DebateResponseModel {
  List<Claims>? claims;

  DebateResponseModel({this.claims});

  DebateResponseModel.fromJson(Map<String, dynamic> json) {
    if (json['claims'] != null) {
      claims = <Claims>[];
      json['claims'].forEach((v) {
        claims!.add(Claims.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (claims != null) {
      data['claims'] = claims!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Claims {
  String? claim;
  String? rating;
  String? explanation;
  List<String>? sources;

  Claims({this.claim, this.rating, this.explanation, this.sources});

  Claims.fromJson(Map<String, dynamic> json) {
    claim = json['claim'];
    rating = json['rating'];
    explanation = json['explanation'];
    sources = json['sources'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['claim'] = claim;
    data['rating'] = rating;
    data['explanation'] = explanation;
    data['sources'] = sources;
    return data;
  }
}
