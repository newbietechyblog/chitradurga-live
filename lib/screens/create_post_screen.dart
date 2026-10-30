import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../services/account_api.dart';
import '../services/session.dart';
import 'sign_in_screen.dart';

const _postTypes = {
  'news': 'News',
  'story': 'Photo story',
  'poster': 'Poster',
  'event': 'Local event',
};

const _postHints = {
  'news': 'Share a local news story. Our editors check it before it goes live.',
  'story': 'Share a photo with your story. A photo is required.',
  'poster': 'Share a poster for a function, programme or notice. A photo is required.',
  'event': 'Add a temple event, festival or programme. Editors check it before it is listed.',
};

const _eventCategories = {
  'temple': 'Temple',
  'festival': 'Festival',
  'programme': 'Programme',
  'other': 'Other',
};

/// Opens the post form. Signs the reader in first if needed.
Future<void> openComposer(BuildContext context, {String type = 'news'}) async {
  var session = await Session.load();
  if (session == null) {
    if (!context.mounted) return;
    final signedIn = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
    if (signedIn != true) return;
    session = await Session.load();
  }
  final current = session;
  if (current == null || !context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CreatePostScreen(session: current, initialType: type),
    ),
  );
}

/// The form for readers to post a news story, photo story, poster or local event.
class CreatePostScreen extends StatefulWidget {
  final Session session;
  final String initialType;

  const CreatePostScreen({super.key, required this.session, this.initialType = 'news'});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _api = AccountApi();
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _location = TextEditingController();
  final _time = TextEditingController();
  final _place = TextEditingController();
  final _phone = TextEditingController();
  final _link = TextEditingController();

  late String _type = widget.initialType;
  String _eventCategory = 'temple';
  DateTime? _eventDate;
  String? _imagePath;
  bool _busy = false;
  String? _error;

  bool get _isEvent => _type == 'event';
  bool get _needsImage => _type == 'story' || _type == 'poster';

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _location.dispose();
    _time.dispose();
    _place.dispose();
    _phone.dispose();
    _link.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked != null && mounted) setState(() => _imagePath = picked.path);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _eventDate = picked);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_needsImage && _imagePath == null) {
      setState(() => _error = 'Please add a photo for this post.');
      return;
    }
    if (_isEvent && _eventDate == null) {
      setState(() => _error = 'Please choose the date of the event.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_isEvent) {
        await _api.createEvent(
          session: widget.session,
          fields: {
            'title': _title.text.trim(),
            'category': _eventCategory,
            'date': DateFormat('yyyy-MM-dd').format(_eventDate!),
            'time': _time.text.trim(),
            'place': _place.text.trim(),
            'phone': _phone.text.trim(),
            'link': _link.text.trim(),
            'description': _body.text.trim(),
          },
        );
      } else {
        await _api.createSubmission(
          session: widget.session,
          kind: _type,
          title: _title.text.trim(),
          body: _body.text.trim(),
          location: _location.text.trim(),
          imagePath: _imagePath,
        );
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Thank you'),
          content: const Text(
            'Your post has been sent to our editors. It will appear in the app once it is checked.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not send your post. Check your internet and try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a post', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type of post
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in _postTypes.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected: _type == entry.key,
                      onSelected: _busy
                          ? null
                          : (_) => setState(() {
                                _type = entry.key;
                                _error = null;
                              }),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _postHints[_type] ?? '',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 16),

              // Photo
              if (_imagePath != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_imagePath!),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : () => setState(() => _imagePath = null),
                  icon: const Icon(Icons.close),
                  label: const Text('Remove photo'),
                ),
              ] else
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pickImage,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(_needsImage ? 'Add photo (required)' : 'Add photo (optional)'),
                ),
              const SizedBox(height: 16),

              // Event-only fields
              if (_isEvent) ...[
                const Text('Type', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in _eventCategories.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: _eventCategory == entry.key,
                        onSelected: _busy
                            ? null
                            : (_) => setState(() => _eventCategory = entry.key),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pickDate,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(_eventDate == null
                      ? 'Choose date'
                      : DateFormat('EEE, d MMM yyyy').format(_eventDate!)),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _time,
                  decoration: const InputDecoration(
                    labelText: 'Time (optional)',
                    hintText: 'For example 6:00 AM',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _place,
                  decoration: const InputDecoration(
                    labelText: 'Place',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact phone (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _link,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Website link (optional)',
                    hintText: 'https://',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Title
              TextFormField(
                controller: _title,
                decoration: InputDecoration(
                  labelText: _isEvent ? 'Event name' : 'Headline',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = (v ?? '').trim().length;
                  final min = _isEvent ? 5 : 10;
                  final max = _isEvent ? 120 : 150;
                  if (n < min) return 'Please write at least $min characters.';
                  if (n > max) return 'Please keep it under $max characters.';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Body
              TextFormField(
                controller: _body,
                minLines: 4,
                maxLines: 10,
                decoration: InputDecoration(
                  labelText: _isEvent ? 'Details (optional)' : 'Write your post',
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (_isEvent) return null;
                  if ((v ?? '').trim().length < 30) {
                    return 'Please write at least 30 characters.';
                  }
                  return null;
                },
              ),

              if (!_isEvent) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _location,
                  decoration: const InputDecoration(
                    labelText: 'Place or area (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],

              const SizedBox(height: 20),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                ),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send to editors'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
