// ignore_for_file: constant_identifier_names

/// Statuts possibles d'un signalement.
enum ReportStatus { signale, en_cours, resolu }

extension ReportStatusX on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.signale:
        return 'Signalé';
      case ReportStatus.en_cours:
        return 'En cours';
      case ReportStatus.resolu:
        return 'Résolu';
    }
  }

  String get emoji {
    switch (this) {
      case ReportStatus.signale:
        return '🔴';
      case ReportStatus.en_cours:
        return '🟠';
      case ReportStatus.resolu:
        return '🟢';
    }
  }

  /// Couleur hexadécimale (#RRGGBB) pour la carte JS.
  String get hexColor {
    switch (this) {
      case ReportStatus.signale:
        return '#EF4444';
      case ReportStatus.en_cours:
        return '#F97316';
      case ReportStatus.resolu:
        return '#22C55E';
    }
  }
}

ReportStatus reportStatusFromString(String? s) {
  switch (s) {
    case 'en_cours':
      return ReportStatus.en_cours;
    case 'resolu':
      return ReportStatus.resolu;
    default:
      return ReportStatus.signale;
  }
}

/// Catégories de signalement.
const kReportCategories = [
  'dépôt sauvage',
  'poubelle débordante',
  'zone polluée',
  'déchets plastiques',
  'déchets chimiques',
  'eau polluée',
  'nuisance sonore',
  'autre',
];

class ReportModel {
  final String id;
  final String? userId;
  final String title;
  final String? description;
  final String category;
  final double latitude;
  final double longitude;
  final ReportStatus status;
  final int upvotes;
  final String? imageUrl;
  final DateTime createdAt;

  const ReportModel({
    required this.id,
    this.userId,
    required this.title,
    this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.upvotes,
    this.imageUrl,
    required this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      title: json['title'] as String? ?? 'Signalement',
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'autre',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: reportStatusFromString(json['status'] as String?),
      upvotes: json['upvotes'] as int? ?? 0,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'title': title,
      if (userId != null) 'user_id': userId,
      if (description != null) 'description': description,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.name,
      'upvotes': upvotes,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }

  ReportModel copyWith({
    ReportStatus? status,
    int? upvotes,
    String? imageUrl,
  }) {
    return ReportModel(
      id: id,
      userId: userId,
      title: title,
      description: description,
      category: category,
      latitude: latitude,
      longitude: longitude,
      status: status ?? this.status,
      upvotes: upvotes ?? this.upvotes,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
    );
  }
}
