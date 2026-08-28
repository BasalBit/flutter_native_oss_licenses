import 'package:flutter/material.dart';
import 'package:flutter_native_oss_licenses/flutter_native_oss_licenses.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerNativeLicenses();
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Native OSS licenses example',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const LicenseSummaryPage(),
    );
  }
}

class LicenseSummaryPage extends StatefulWidget {
  const LicenseSummaryPage({super.key});

  @override
  State<LicenseSummaryPage> createState() => _LicenseSummaryPageState();
}

class _LicenseSummaryPageState extends State<LicenseSummaryPage> {
  late final Future<List<MergedLicenseEntry>> _licenses = loadMergedLicenses();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Merged OSS licenses')),
      body: FutureBuilder<List<MergedLicenseEntry>>(
        future: _licenses,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load licenses: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Center(
            child: Text('${snapshot.data!.length} grouped license records'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showLicensePage(
          context: context,
          applicationName: 'Native OSS licenses example',
        ),
        icon: const Icon(Icons.description_outlined),
        label: const Text('Flutter license page'),
      ),
    );
  }
}
