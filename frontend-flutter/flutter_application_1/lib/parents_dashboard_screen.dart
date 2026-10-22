import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────
// 📦 DATA MODELS
// ─────────────────────────────────────────────────────────────

class PhotoItem {
  final String id;
  final String source; // URL (default image) or local file path (uploaded)
  final bool isNetwork;

  PhotoItem({required this.id, required this.source, required this.isNetwork});

  Map<String, dynamic> toJson() =>
      {'id': id, 'source': source, 'isNetwork': isNetwork};

  factory PhotoItem.fromJson(Map<String, dynamic> j) => PhotoItem(
        id: j['id'] as String,
        source: j['source'] as String,
        isNetwork: j['isNetwork'] as bool,
      );
}

class TopicGroup {
  final String id;
  final String category; // family | likes | fears | behaviours
  String title;
  final List<PhotoItem> photos;

  TopicGroup({
    required this.id,
    required this.category,
    required this.title,
    List<PhotoItem>? photos,
  }) : photos = photos ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'title': title,
        'photos': photos.map((p) => p.toJson()).toList(),
      };

  factory TopicGroup.fromJson(Map<String, dynamic> j) => TopicGroup(
        id: j['id'] as String,
        category: j['category'] as String,
        title: j['title'] as String,
        photos: (j['photos'] as List)
            .map((p) => PhotoItem.fromJson(Map<String, dynamic>.from(p)))
            .toList(),
      );
}

class _CategoryInfo {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _CategoryInfo(this.key, this.title, this.subtitle, this.icon, this.color);
}

// ─────────────────────────────────────────────────────────────
// 👨‍👩‍👧 PARENTS DASHBOARD
// ─────────────────────────────────────────────────────────────

class ParentsDashboardScreen extends StatefulWidget {
  const ParentsDashboardScreen({super.key});

  @override
  State<ParentsDashboardScreen> createState() => _ParentsDashboardScreenState();
}

class _ParentsDashboardScreenState extends State<ParentsDashboardScreen> {
  static const String _storeKey = 'parents_dashboard_v1';

  // 🎨 Same calm palette as the home page
  static const Color _primary = Color(0xFF5C6BC0);
  static const Color _bgTop = Color(0xFFE8EAF6);
  static const Color _bgBottom = Color(0xFFF3E5F5);

  // 🖼️ Background image (declare it in pubspec.yaml under assets)
  static const String _bgAsset = 'assets/images/r1.jpg';

  static const List<_CategoryInfo> _categories = [
    _CategoryInfo('family', 'Family', 'Photos of Mom, Dad and loved ones',
        Icons.family_restroom_rounded, Color(0xFF42A5F5)),
    _CategoryInfo('likes', 'Things My Child Loves',
        'Hobbies and things that bring happiness', Icons.favorite_rounded,
        Color(0xFFFFA726)),
    _CategoryInfo('fears', 'Fears & Triggers',
        'Things that scare or upset my child', Icons.warning_amber_rounded,
        Color(0xFFEF5350)),
    _CategoryInfo('behaviours', 'Other Behaviours',
        'Calming things, sensitivities, routines', Icons.psychology_rounded,
        Color(0xFF26A69A)),
  ];

  final ImagePicker _picker = ImagePicker();
  List<TopicGroup> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ───────────── DEFAULT DATA (initial Google-style images) ─────────────

  PhotoItem _net(String id, String keywords, int lock) => PhotoItem(
        id: id,
        source: 'https://loremflickr.com/400/400/$keywords?lock=$lock',
        isNetwork: true,
      );

  List<TopicGroup> _defaultGroups() => [
        TopicGroup(
          id: 'dad',
          category: 'family',
          title: 'Dad',
          photos: [_net('dad1', 'father,man', 11)],
        ),
        TopicGroup(
          id: 'mom',
          category: 'family',
          title: 'Mom',
          photos: [_net('mom1', 'mother,woman', 12)],
        ),
        TopicGroup(
          id: 'cricket',
          category: 'likes',
          title: 'Cricket 🏏',
          photos: [_net('cricket1', 'cricket,bat', 13)],
        ),
        TopicGroup(
          id: 'magic',
          category: 'likes',
          title: 'Magic ✨',
          photos: [_net('magic1', 'magic,magician', 14)],
        ),
        TopicGroup(
          id: 'dark',
          category: 'fears',
          title: 'Darkness 🌑',
          photos: [_net('dark1', 'dark,night', 15)],
        ),
        TopicGroup(
          id: 'cat',
          category: 'fears',
          title: 'Cats 🐱',
          photos: [_net('cat1', 'cat', 16)],
        ),
        TopicGroup(
          id: 'noise',
          category: 'behaviours',
          title: 'Loud Noises 🔊',
          photos: [_net('noise1', 'fireworks', 17)],
        ),
        TopicGroup(
          id: 'music',
          category: 'behaviours',
          title: 'Calms Down With Music 🎧',
          photos: [_net('music1', 'headphones,music', 18)],
        ),
        TopicGroup(
          id: 'food',
          category: 'behaviours',
          title: 'Favourite Food 🍕',
          photos: [_net('food1', 'pizza', 19)],
        ),
      ];

  // ───────────── STORAGE ─────────────

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storeKey);
      if (raw == null) {
        _groups = _defaultGroups();
        await _save();
      } else {
        final list = jsonDecode(raw) as List;
        _groups = list
            .map((g) => TopicGroup.fromJson(Map<String, dynamic>.from(g)))
            .toList();
      }
    } catch (_) {
      _groups = _defaultGroups();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _storeKey, jsonEncode(_groups.map((g) => g.toJson()).toList()));
  }

  Future<void> _deleteLocalFile(PhotoItem p) async {
    if (p.isNetwork) return;
    try {
      final f = File(p.source);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  // ───────────── ACTIONS ─────────────

  /// 📤 Upload one or many photos into a group
  Future<void> _addPhotos(TopicGroup group) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add photos to "${group.title}"',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: _primary),
                title: const Text('Choose from gallery (multiple)'),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              ListTile(
                leading:
                    const Icon(Icons.camera_alt_rounded, color: _primary),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == null) return;

    try {
      List<XFile> files = [];
      if (choice == 'gallery') {
        files = await _picker.pickMultiImage(imageQuality: 85);
      } else {
        final f = await _picker.pickImage(
            source: ImageSource.camera, imageQuality: 85);
        if (f != null) files = [f];
      }
      if (files.isEmpty) return;

      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/parent_photos');
      if (!await folder.exists()) await folder.create(recursive: true);

      for (var i = 0; i < files.length; i++) {
        final id = '${DateTime.now().microsecondsSinceEpoch}_$i';
        final ext = files[i].path.contains('.')
            ? files[i].path.split('.').last
            : 'jpg';
        final dest = '${folder.path}/$id.$ext';
        await File(files[i].path).copy(dest);
        group.photos.add(PhotoItem(id: id, source: dest, isNetwork: false));
      }

      setState(() {});
      await _save();
      _snack('${files.length} photo(s) added to ${group.title}');
    } catch (e) {
      _snack('Could not add photos. Please check permissions.');
    }
  }

  /// 🗑️ Delete a single photo
  Future<void> _deletePhoto(TopicGroup group, PhotoItem photo) async {
    final ok = await _confirm('Delete this photo?',
        'It will be removed from "${group.title}".');
    if (!ok) return;
    await _deleteLocalFile(photo);
    setState(() => group.photos.removeWhere((p) => p.id == photo.id));
    await _save();
  }

  /// ➕ Add a new custom topic (e.g. "Swimming", "Dogs")
  Future<void> _addTopic(_CategoryInfo cat) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('New topic in ${cat.title}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
              hintText: 'e.g. Swimming, Dogs, Vacuum cleaner'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Add')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    setState(() => _groups.add(TopicGroup(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        category: cat.key,
        title: name)));
    await _save();
  }

  /// 🗑️ Delete a whole topic with all of its photos
  Future<void> _deleteGroup(TopicGroup group) async {
    final ok = await _confirm('Delete "${group.title}"?',
        'This topic and all its photos will be removed.');
    if (!ok) return;
    for (final p in group.photos) {
      await _deleteLocalFile(p);
    }
    setState(() => _groups.removeWhere((g) => g.id == group.id));
    await _save();
  }

  /// 🔄 Restore the initial sample images and topics
  Future<void> _resetDefaults() async {
    final ok = await _confirm('Reset everything?',
        'All uploaded photos will be deleted and the sample images restored.');
    if (!ok) return;
    for (final g in _groups) {
      for (final p in g.photos) {
        await _deleteLocalFile(p);
      }
    }
    setState(() => _groups = _defaultGroups());
    await _save();
  }

  Future<bool> _confirm(String title, String message) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    return r ?? false;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Text(msg),
    ));
  }

  void _viewPhoto(TopicGroup group, PhotoItem photo) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: InteractiveViewer(child: _photoImage(photo, BoxFit.contain)),
            ),
            const SizedBox(height: 10),
            Text(group.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close, color: Colors.white),
              label:
                  const Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────── UI ─────────────

  Widget _photoImage(PhotoItem p, BoxFit fit) {
    Widget broken() => Container(
          color: Colors.grey.shade200,
          child: const Center(
              child: Icon(Icons.broken_image_rounded, color: Colors.grey)),
        );
    if (p.isNetwork) {
      return Image.network(
        p.source,
        fit: fit,
        loadingBuilder: (c, child, prog) => prog == null
            ? child
            : Container(
                color: Colors.grey.shade100,
                child: const Center(
                    child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2)))),
        errorBuilder: (c, e, s) => broken(),
      );
    }
    return Image.file(File(p.source),
        fit: fit, errorBuilder: (c, e, s) => broken());
  }

  Widget _photoTile(TopicGroup group, PhotoItem photo) {
    return Padding(
      padding: const EdgeInsets.only(right: 12, top: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: () => _viewPhoto(group, photo),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                  width: 110,
                  height: 110,
                  child: _photoImage(photo, BoxFit.cover)),
            ),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: GestureDetector(
              onTap: () => _deletePhoto(group, photo),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Colors.redAccent, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addTile(TopicGroup group, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: () => _addPhotos(group),
        child: Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_rounded, color: color, size: 32),
              const SizedBox(height: 4),
              Text('Upload',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _groupCard(TopicGroup group, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 14,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(group.title,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238))),
              ),
              Text('${group.photos.length}',
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600)),
              IconButton(
                tooltip: 'Delete topic',
                icon: Icon(Icons.delete_outline_rounded,
                    color: Colors.grey.shade600),
                onPressed: () => _deleteGroup(group),
              ),
            ],
          ),
          SizedBox(
            height: 125,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                ...group.photos.map((p) => _photoTile(group, p)),
                _addTile(group, color),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categorySection(_CategoryInfo cat) {
    final groups = _groups.where((g) => g.category == cat.key).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: cat.color, borderRadius: BorderRadius.circular(14)),
                child: Icon(cat.icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.title,
                        style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF283593))),
                    Text(cat.subtitle,
                        style: TextStyle(
                            fontSize: 12.5, color: Colors.grey.shade800)),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _addTopic(cat),
                icon: Icon(Icons.add_circle_outline, color: cat.color),
                label: Text('Topic', style: TextStyle(color: cat.color)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (groups.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16)),
              child: const Text('No topics yet. Tap "+ Topic" to add one.'),
            )
          else
            ...groups.map((g) => _groupCard(g, cat.color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF283593)),
        title: const Text('Parents Dashboard',
            style: TextStyle(
                color: Color(0xFF283593), fontWeight: FontWeight.w800)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF283593)),
            onSelected: (v) {
              if (v == 'reset') _resetDefaults();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'reset', child: Text('Reset to sample images')),
            ],
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_bgTop, _bgBottom]),
        ),
        child: Stack(
          children: [
            // 📷 Background r1.jpg
            Positioned.fill(
              child: Image.asset(
                _bgAsset,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const SizedBox.shrink(),
              ),
            ),
            // 🌫️ Soft overlay for readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _bgTop.withOpacity(0.70),
                      _bgTop.withOpacity(0.80),
                      _bgBottom.withOpacity(0.92),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16)),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: _primary),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Add photos of family, favourite things and fears so the app can personalise learning for your child. Tap a photo to enlarge it, tap ✕ to delete it.',
                                  style: TextStyle(fontSize: 13.5, height: 1.35),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ..._categories.map(_categorySection),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}