// ============================================================
// YECO - تعديل بيانات الحساب (UPDATE في SQLite)
// ============================================================

import 'package:flutter/material.dart';

import '../../state/store.dart';
import '../shared/widgets.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _city;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final u = AppScope.sessionOf(context, listen: false).user!;
    _name = TextEditingController(text: u.name);
    _phone = TextEditingController(text: u.phone);
    _city = TextEditingController(text: u.city);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    await AppScope.sessionOf(context, listen: false).updateProfile(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      city: _city.text.trim(),
    );
    if (!mounted) return;
    notify(context, 'تم حفظ بياناتك');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final u = AppScope.sessionOf(context).user!;
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل البيانات')),
      body: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              initialValue: u.email,
              enabled: false,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني (لا يمكن تغييره)',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              validator: V.name,
              decoration: const InputDecoration(
                labelText: 'الاسم الكامل',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              validator: V.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الجوال',
                prefixIcon: Icon(Icons.phone_android_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _city,
              validator: (v) => V.required(v, 'المدينة'),
              decoration: const InputDecoration(
                labelText: 'المدينة',
                prefixIcon: Icon(Icons.location_city_rounded),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _busy ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ التغييرات'),
            ),
          ],
        ),
      ),
    );
  }
}
