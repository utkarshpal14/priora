class AppVersionModel {
  final String latestVersion;
  final String minSupportedVersion;
  final String apkDownloadUrl;
  final String releaseNotes;
  final bool forceUpdate;

  const AppVersionModel({
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.apkDownloadUrl,
    required this.releaseNotes,
    this.forceUpdate = false,
  });

  factory AppVersionModel.fromJson(Map<String, dynamic> json) {
    return AppVersionModel(
      latestVersion: json['latest_version'] as String? ?? '1.0.0',
      minSupportedVersion: json['min_supported_version'] as String? ?? '1.0.0',
      apkDownloadUrl: json['apk_download_url'] as String? ?? '',
      releaseNotes: json['release_notes'] as String? ?? '',
      forceUpdate: json['force_update'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latest_version': latestVersion,
      'min_supported_version': minSupportedVersion,
      'apk_download_url': apkDownloadUrl,
      'release_notes': releaseNotes,
      'force_update': forceUpdate,
    };
  }
}
