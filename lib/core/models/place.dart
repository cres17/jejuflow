class TourPlace {
  final String contentId;
  final String contentTypeId;
  final String title;
  final String addr;
  final String tel;
  final String imageUrl;
  final String thumbUrl;
  final double? lat;
  final double? lng;
  final String cat1;
  final String cat2;
  final String cat3;

  const TourPlace({
    required this.contentId,
    required this.contentTypeId,
    required this.title,
    required this.addr,
    required this.tel,
    required this.imageUrl,
    required this.thumbUrl,
    this.lat,
    this.lng,
    this.cat1 = '',
    this.cat2 = '',
    this.cat3 = '',
  });

  bool get hasImage => imageUrl.isNotEmpty;
  String get displayImage => thumbUrl.isNotEmpty ? thumbUrl : imageUrl;

  factory TourPlace.fromApi(Map<String, dynamic> m) {
    final thumb = _httpsImageUrl(m['firstimage2']?.toString() ?? '');
    final orig = _httpsImageUrl(m['firstimage']?.toString() ?? '');
    return TourPlace(
      contentId: m['contentid']?.toString() ?? '',
      contentTypeId: m['contenttypeid']?.toString() ?? '',
      title: m['title']?.toString() ?? '',
      addr: m['addr1']?.toString() ?? '',
      tel: m['tel']?.toString() ?? '',
      imageUrl: orig,
      thumbUrl: thumb.isNotEmpty ? thumb : orig,
      lat: double.tryParse(m['mapy']?.toString() ?? ''),
      lng: double.tryParse(m['mapx']?.toString() ?? ''),
      cat1: m['cat1']?.toString() ?? '',
      cat2: m['cat2']?.toString() ?? '',
      cat3: m['cat3']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'contentId': contentId,
        'contentTypeId': contentTypeId,
        'title': title,
        'addr': addr,
        'tel': tel,
        'imageUrl': imageUrl,
        'thumbUrl': thumbUrl,
        'lat': lat,
        'lng': lng,
        'cat1': cat1,
        'cat2': cat2,
        'cat3': cat3,
      };

  factory TourPlace.fromCached(Map<String, dynamic> m) => TourPlace(
        contentId: m['contentId'],
        contentTypeId: m['contentTypeId'],
        title: m['title'],
        addr: m['addr'],
        tel: m['tel'],
        imageUrl: _httpsImageUrl(m['imageUrl']?.toString() ?? ''),
        thumbUrl: _httpsImageUrl(m['thumbUrl']?.toString() ?? ''),
        lat: m['lat'] != null ? (m['lat'] as num).toDouble() : null,
        lng: m['lng'] != null ? (m['lng'] as num).toDouble() : null,
        cat1: m['cat1']?.toString() ?? '',
        cat2: m['cat2']?.toString() ?? '',
        cat3: m['cat3']?.toString() ?? '',
      );
}

enum PlaceType { tourist, restaurant, cafe }

String _httpsImageUrl(String url) {
  if (url.startsWith('http://tong.visitkorea.or.kr/')) {
    return url.replaceFirst('http://', 'https://');
  }
  return url;
}
