import 'package:equatable/equatable.dart';

class AboutData extends Equatable {
  final String companyName;
  final String companyTagline;
  final String bannerImagePath;
  final String logoImagePath;
  final String mission;
  final String vision;
  final String appPurpose;
  final String websiteUrl;
  final String email;
  final String copyright;
  final String ourMissionTitle;
  final String ourVisionTitle;
  final String whyWeBuildVocarioTitle;

  const AboutData({
    required this.companyName,
    required this.companyTagline,
    required this.bannerImagePath,
    required this.logoImagePath,
    required this.mission,
    required this.vision,
    required this.appPurpose,
    required this.websiteUrl,
    required this.email,
    required this.copyright,
    required this.ourMissionTitle,
    required this.ourVisionTitle,
    required this.whyWeBuildVocarioTitle,
  });

  @override
  List<Object?> get props => [
        companyName,
        companyTagline,
        bannerImagePath,
        logoImagePath,
        mission,
        vision,
        appPurpose,
        websiteUrl,
        email,
        copyright,
        ourMissionTitle,
        ourVisionTitle,
        whyWeBuildVocarioTitle,
      ];
}