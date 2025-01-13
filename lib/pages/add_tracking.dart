import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../constants/courier_constants.dart';

class AddTrackingPage extends StatefulWidget {
  const AddTrackingPage({Key? key}) : super(key: key);

  @override
  State<AddTrackingPage> createState() => _AddTrackingPageState();
}

class _AddTrackingPageState extends State<AddTrackingPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _resiController = TextEditingController();
  String? _selectedCourier;
  bool _isLoading = false;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _initApiService();
  }

  Future<void> _initApiService() async {
    final prefs = await SharedPreferences.getInstance();
    _apiService = ApiService(prefs);
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Use default title if empty
        final title = _titleController.text.trim().isEmpty
            ? 'Shipment ${_resiController.text}'
            : _titleController.text;

        await _apiService.addResi(
          _resiController.text,
          title,
          _selectedCourier!,
        );

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Resi'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCourier,
              decoration: const InputDecoration(
                labelText: 'Pilih Kurir',
                hintText: 'Pilih Kurir',
                border: OutlineInputBorder(),
              ),
              items: CourierConstants.courierNames.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCourier = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Silakan pilih kurir';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _resiController,
              decoration: const InputDecoration(
                labelText: 'Nomor Resi',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter tracking number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title (Optional)',
                hintText: 'Leave empty to use tracking number as title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _resiController.dispose();
    super.dispose();
  }
}
