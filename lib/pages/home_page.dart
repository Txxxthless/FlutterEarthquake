import 'package:flutter/material.dart';
import 'package:flutter_earthquake/pages/settings_page.dart';
import 'package:flutter_earthquake/providers/app_data_provider.dart';
import 'package:flutter_earthquake/utils/helper_functions.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void didChangeDependencies() {
    Provider.of<AppDataProvider>(context, listen: false).init();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earthquake App'),
        actions: [
          IconButton(
            onPressed: showSortingDialog,
            icon: const Icon(Icons.sort),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsPage(),
              ),
            ),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Consumer<AppDataProvider>(
        builder: (context, provider, child) => provider.hasDataLoaded
            ? provider.earthquakeModel!.features!.isEmpty
                ? const Center(
                    child: Text(
                      'Nothing found',
                    ),
                  )
                : ListView.builder(
                    itemCount: provider.earthquakeModel!.features!.length,
                    itemBuilder: (context, index) {
                      final data = provider
                          .earthquakeModel!.features![index].properties!;
                      return ListTile(
                        title: Text(
                          data.place ?? data.title ?? 'Unknown',
                        ),
                        subtitle: Text(
                          getFormatterDateTime(
                            data.time!,
                            'EEE MM dd yyyy hh:mm a',
                          ),
                        ),
                        trailing: Chip(
                          avatar: data.alert == null
                              ? null
                              : CircleAvatar(
                                  backgroundColor:
                                      provider.getAlertColor(data.alert!),
                                ),
                          label: Text(
                            '${data.mag}',
                          ),
                        ),
                      );
                    },
                  )
            : const Center(
                child: Text('Please wait'),
              ),
      ),
    );
  }

  void showSortingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort by'),
        content: Consumer<AppDataProvider>(
          builder: (context, provider, child) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioGroup(
                value: 'magnitude',
                groupValue: provider.orderBy,
                label: 'Magnitude-Desc',
                onChange: (value) {
                  provider.setOrder(value!);
                },
              ),
              RadioGroup(
                value: 'magnitude-asc',
                groupValue: provider.orderBy,
                label: 'Magnitude-Asc',
                onChange: (value) {
                  provider.setOrder(value!);
                },
              ),
              RadioGroup(
                value: 'time',
                groupValue: provider.orderBy,
                label: 'Time-Desc',
                onChange: (value) {
                  provider.setOrder(value!);
                },
              ),
              RadioGroup(
                value: 'time-asc',
                groupValue: provider.orderBy,
                label: 'Time-Asc',
                onChange: (value) {
                  provider.setOrder(value!);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class RadioGroup extends StatelessWidget {
  final String groupValue;
  final String value;
  final String label;
  final Function(String?) onChange;
  const RadioGroup({
    super.key,
    required this.groupValue,
    required this.value,
    required this.label,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: groupValue,
          onChanged: onChange,
        ),
        Text(label),
      ],
    );
  }
}
