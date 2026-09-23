import 'package:roble/roble.dart';

/// Runtime configuration supplied with `--dart-define`.
class RobleConfig {
  const RobleConfig({required this.baseUrl, required this.contractId});

  final String baseUrl;
  final String contractId;

  static const fromEnvironment = RobleConfig(
    baseUrl: String.fromEnvironment('ROBLE_BASE_URL'),
    contractId: String.fromEnvironment('ROBLE_CONTRACT_ID'),
  );

  bool get isConfigured {
    final normalizedBaseUrl = baseUrl.trim();
    final normalizedContractId = contractId.trim();
    final uri = Uri.tryParse(normalizedBaseUrl);

    return normalizedBaseUrl.isNotEmpty &&
        normalizedContractId.isNotEmpty &&
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty &&
        !normalizedContractId.contains(' ') &&
        normalizedContractId != 'tu_contrato' &&
        normalizedContractId != 'mi_contrato';
  }

  RobleApiDataBase createClient() => RobleApiDataBase(
    config: RobleApiConfig.fromContract(
      baseUrl: baseUrl.trim(),
      contractId: contractId.trim(),
    ),
  );
}