import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';

import '../models/uploaded_file.dart';
import '../providers/login_service_provider.dart';
import '../services/login_service.dart';
import '../providers/upload_provider.dart';

enum MediaType { photos, videos, docs, apks, others }

/// ---------------- PROVIDERS ----------------

final selectedTabProvider = StateProvider<MediaType>((ref) => MediaType.photos);

final mediaProvider =
    StateNotifierProvider<MediaNotifier, AsyncValue<List<UploadedFile>>>(
      (ref) => MediaNotifier(),
    );

Uint8List? safeBase64Decode(String? b64) {
  if (b64 == null) return null;

  final cleaned = b64
      .replaceAll('\n', '')
      .replaceAll('\r', '')
      .replaceAll(' ', '');

  if (cleaned.isEmpty) return null;

  try {
    return base64Decode(cleaned);
  } catch (e) {
    debugPrint('Base64 decode failed: $e');
    return null;
  }
}

/// ---------------- STATE NOTIFIER ----------------

class MediaNotifier extends StateNotifier<AsyncValue<List<UploadedFile>>> {
  MediaNotifier() : super(const AsyncLoading()) {
    _init();
  }

  final LoginService _service = LoginService();
  final Box<UploadedFile> _box = Hive.box<UploadedFile>('mediaBox');
  final Map<int, Uint8List?> thumbCache = {};
  int _lastMessageId = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  static const int _pageSize = 20;
  Set<int> _knownIds = {};

  void _init() {
    if (_box.isNotEmpty) {
      final cached = _box.values.toList();
      state = AsyncData(cached);

      _knownIds = cached.map((e) => e.fileId).toSet();
      _lastMessageId = cached.last.fileId;
    } else {
      fetchNextPage();
    }
  }


  Future<void> fetchNextPage() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;

    try {
      final fetched = await _service.fetchMedia(
        offsetId: _lastMessageId,
        limit: _pageSize,
      );

      if (fetched.isEmpty) {
        _hasMore = false;
        return;
      }

      final fetchedLastId = fetched.last['file_id'];

      final newFiles = fetched
          .where((e) => !_knownIds.contains(e['file_id']))
          .map((e) {
        final id = e['file_id'];
        _knownIds.add(id);

        return UploadedFile(
          fileId: id,
          name: e['file_name'],
          size: e['file_size'],
          path: '',
          type: e['type'],
          caption: e['caption'],
          thumbBytes: safeBase64Decode(e['thumbnail_base64']),
        );
      })
          .toList();


      _lastMessageId = fetchedLastId;
      await _box.addAll(newFiles);
      state = AsyncData(_box.values.toList());

    } catch (_) {
      // offline-safe: keep Hive data
    } finally {
      _isLoadingMore = false;
    }
  }

  /// FILTERING (case-insensitive, robust)
  List<UploadedFile> filtered(MediaType tab, [List<UploadedFile>? source]) {
    final all =
        (source ?? _box.values.toList())
            .where(
              (f) => (f.caption ?? '').toLowerCase().contains(
                'uploaded via zerolimit',
              ),
            )
            .toList();

    return all.where((file) {
      switch (tab) {
        case MediaType.photos:
          return file.type == 'photo';
        case MediaType.videos:
          return file.type == 'video';
        case MediaType.docs:
          return file.type == 'doc' || file.type == 'document';
        case MediaType.apks:
          return file.name.toLowerCase().endsWith('.apk');
        case MediaType.others:
          return !(file.type == 'photo' ||
              file.type == 'video' ||
              file.type == 'doc' ||
              file.name.toLowerCase().endsWith('.apk'));
      }
    }).toList();
  }

  Future<int> addUploadedFileImmediately({
    required String fileName,
    required String type,
    String? caption,
  }) async {
    final tempId = DateTime.now().millisecondsSinceEpoch;
    final current = state.asData?.value ?? <UploadedFile>[];

    final newFile = UploadedFile(
      fileId: tempId,
      name: fileName,
      size: 0,
      path: '',
      type: type,
      caption: caption,
      thumbBytes: null,
    );

    state = AsyncData([newFile, ...current]);
    return tempId;
  }

  void replaceTempWithReal(int tempId, UploadedFile realFile){
    final current = state.asData?.value ?? <UploadedFile>[];
    final index = current.indexWhere((f) => f.fileId == tempId);
    if (index == -1) return;

    final updated = [...current];
    updated[index] = realFile;
    state = AsyncData(updated);
  }
}

/// ---------------- HOME UI ----------------

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(selectedTabProvider);
    final mediaState = ref.watch(mediaProvider);

    return Scaffold(
      backgroundColor: const Color.fromRGBO(244, 225, 102, 1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          tab.name.toUpperCase(),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: mediaState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (_, __) => const Center(child: Text("Failed to load files")),
              data: (_) => const _FileGrid(),
            ),
          ),
        ],
      ),
      floatingActionButton: const _UploadFab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tab.index,
        onTap:
            (i) =>
                ref.read(selectedTabProvider.notifier).state =
                    MediaType.values[i],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.photo_library), label: 'Photos',),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Videos',),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Docs'),
          BottomNavigationBarItem(icon: Icon(Icons.android), label: 'APKs'),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'Others',
          ),
        ],
      ),
    );
  }
}

Future<void> saveBytesToFile(List<int> bytes, String fileName) async {
  final directory = Directory('/storage/emulated/0/Download');
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(bytes);
}

/// ---------------- GRID ----------------

class _FileGrid extends ConsumerStatefulWidget {
  const _FileGrid({super.key});

  @override
  ConsumerState<_FileGrid> createState() => _FileGridState();
}

class _FileGridState extends ConsumerState<_FileGrid> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();

    _controller.addListener(() {
      if (_controller.position.pixels >=
          _controller.position.maxScrollExtent - 300) {
        ref.read(mediaProvider.notifier).fetchNextPage();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
@override
Widget build(BuildContext context) {
    final tab = ref.watch(selectedTabProvider);
    final notifier = ref.read(mediaProvider.notifier);
    final mediaState = ref.watch(mediaProvider);
    final files = mediaState.when(
      data: (list) => notifier.filtered(tab),
      loading: () => <UploadedFile>[],
      error: (_, __) => <UploadedFile>[],
    );

    if (files.isEmpty) {
      return const Center(child: Text("No files uploaded yet."));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      controller: _controller,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final thumb = notifier.thumbCache.putIfAbsent(
          file.fileId,
          () => file.thumbBytes,
        );
        return Card(
          elevation: 4,
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Expanded(
                  child:
                      thumb != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              thumb,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              gaplessPlayback: true,
                            ),
                          )
                          : const Icon(Icons.insert_drive_file, size: 80),
                ),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final bytes = await ref
                              .read(loginServiceProvider)
                              .downloadMedia(file.fileId);
                          await saveBytesToFile(bytes, file.name);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('File saved to Downloads'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text(
                          "Save",
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(
                            191,
                            107,
                            207,
                            1.0,
                          ),
                          foregroundColor: Colors.black,
                          minimumSize: const Size(80, 35),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: const BorderSide(color: Colors.black, width: 1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref.read(loginServiceProvider).viewMedia(
                            context,
                            file.fileId,
                            file.type ?? 'other',
                          );
                        },
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text(
                          "View",
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(
                            191,
                            107,
                            207,
                            1.0,
                          ),
                          foregroundColor: Colors.black,
                          minimumSize: const Size(80, 35),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: const BorderSide(color: Colors.black, width: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ---------------- FAB ----------------

class _UploadFab extends ConsumerWidget {
  const _UploadFab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () => _showOptions(context, ref),
      child: const Icon(Icons.upload),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(mediaProvider.notifier);
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder:
          (_) => Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text("Upload Photo"),
                onTap: () async {
                  Navigator.pop(context);
                  final f = await picker.pickImage(source: ImageSource.gallery);
                  if (f != null) {
                    final service = ref.read(loginServiceProvider);
                    showUploadSnackBar(context, ref, fileName: f.name);
                    try {
                      final tempId = await notifier.addUploadedFileImmediately(
                        fileName: f.name,
                        type: 'photo',
                        caption: 'uploaded via zerolimit',
                      );
                      final response = await service.uploadFile(
                        f,
                        onProgress: (p) {
                          ref.read(uploadProgressProvider.notifier).state = p;
                        },
                      );
                      final realFile = UploadedFile(
                        fileId: response['file_id'],
                        name: response['file_name'],
                        size: response['file_size'] ?? 0,
                        path: '',
                        type: 'photo',
                        caption: response['caption'],
                        thumbBytes: safeBase64Decode(response['thumbnail_base64']),
                      );
                      notifier.replaceTempWithReal(tempId, realFile);
                      await Hive.box<UploadedFile>('mediaBox').add(realFile);
                      ref.read(uploadProgressProvider.notifier).state = null;
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    } catch (e) {
                      ref.read(uploadProgressProvider.notifier).state = null;
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(content: Text('Upload failed')),
                        );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_collection),
                title: const Text("Upload Video"),
                onTap: () async {
                  Navigator.pop(context);
                  final f = await picker.pickVideo(source: ImageSource.gallery);
                  if (f != null) {
                    final service = ref.read(loginServiceProvider);
                    showUploadSnackBar(context, ref, fileName: f.name);
                    try {
                      final tempId = await notifier.addUploadedFileImmediately(
                        fileName: f.name,
                        type: 'video',
                        caption: 'uploaded via zerolimit',
                      );
                      final response = await service.uploadFile(
                        f,
                        onProgress: (p) {
                          ref.read(uploadProgressProvider.notifier).state = p;
                        },
                      );
                      final realFile = UploadedFile(
                        fileId: response['file_id'],
                        name: response['file_name'],
                        size: response['file_size'] ?? 0,
                        path: '',
                        type: 'video',
                        caption: response['caption'],
                        thumbBytes: safeBase64Decode(response['thumbnail_base64']),
                      );
                      notifier.replaceTempWithReal(tempId, realFile);
                      await Hive.box<UploadedFile>('mediaBox').add(realFile);
                      ref.read(uploadProgressProvider.notifier).state = null;
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    } catch (e) {
                      ref.read(uploadProgressProvider.notifier).state = null;
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(content: Text('Upload failed')),
                        );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text("Upload File"),
                  onTap: () async {
                    Navigator.pop(context);
                    final service = ref.read(loginServiceProvider);
                    final r = await FilePicker.platform.pickFiles();
                    if (r == null || r.files.isEmpty || r.files.single.path == null) {
                      return;
                    }
                    final file = XFile(r.files.single.path!);
                    final tempId = await notifier.addUploadedFileImmediately(
                      fileName: r.files.single.name,
                      type: 'other',
                      caption: 'uploaded via zerolimit',
                    );

                    final response = await service.uploadFile(
                      file,
                      onProgress: (p) {
                        ref.read(uploadProgressProvider.notifier).state = p;
                      },
                    );

                    ref.read(uploadProgressProvider.notifier).state = null;

                    final realFile = UploadedFile(
                      fileId: response['file_id'],
                      name: response['file_name'],
                      size: response['file_size'] ?? 0,
                      path: '',
                      type: 'other',
                      caption: response['caption'],
                      thumbBytes: safeBase64Decode(response['thumbnail_base64']),
                    );

                    notifier.replaceTempWithReal(tempId, realFile);
                    await Hive.box<UploadedFile>('mediaBox').add(realFile);
                    ref.read(uploadProgressProvider.notifier).state = null;
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  }
              ),
            ],
          ),
    );
  }
}

void showUploadSnackBar(
  BuildContext context,
  WidgetRef ref, {
  required String fileName,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(days: 1),
      content: Consumer(
        builder: (context, ref, _) {
          final p = ref.watch(uploadProgressProvider);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (p != null) ...[
                LinearProgressIndicator(value: p),
                const SizedBox(height: 6),
                Text('${(p * 100).toInt()}%'),
              ] else
                const Text('Finalizing upload…'),
            ],
          );
        },
      ),
    ),
  );
}
