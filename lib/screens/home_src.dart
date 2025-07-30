import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zerolimit/models/uploaded_file.dart';
import 'package:zerolimit/services/login_service.dart';

enum MediaType { photos, videos, docs, apks, others }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

Widget _buildFallbackIcon(String? type) {
  switch (type) {
    case 'photo':
      return const Icon(Icons.image, size: 80, color: Colors.white70);
    case 'video':
      return const Icon(Icons.videocam, size: 80, color: Colors.white70);
    case 'doc':
    case 'document':
      return const Icon(Icons.description, size: 80, color: Colors.white70);
    case 'apk':
      return const Icon(Icons.android, size: 80, color: Colors.white70);
    default:
      return const Icon(
        Icons.insert_drive_file,
        size: 80,
        color: Colors.white70,
      );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  final LoginService loginService = LoginService();
  final ImagePicker _picker = ImagePicker();
  MediaType _selectedTab = MediaType.photos;
  //final List<UploadedFile> uploadedFiles = [];
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _showFabNotifier = ValueNotifier(true);
  late Box<UploadedFile> mediaBox;

  @override
  void initState() {
    super.initState();
    mediaBox = Hive.box<UploadedFile>('mediaBox');
    if (mediaBox.isEmpty) {
      fetchFilesFromBackend();
    }

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (_showFabNotifier.value) _showFabNotifier.value = false;
      } else if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (!_showFabNotifier.value) _showFabNotifier.value = true;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _showFabNotifier.dispose();
    super.dispose();
  }

  Future<void> fetchFilesFromBackend() async {
    final fetched = await loginService.fetchMedia();
    print("Total files fetched: ${fetched.length}");
    await mediaBox.clear();
    for (var f in fetched) {
      print(
        "${f['file_name']} | Type: ${f['type']} | Thumb: ${f['thumbnail_base64']?.length}",
      );
    }
    final files =
        fetched
            .map(
              (e) => UploadedFile(
                fileId: e['file_id'],
                name: e['file_name'] ?? "Unnamed",
                size: e['file_size'] ?? 0,
                path: "",
                type: (e['type'] ?? '').toString().toLowerCase(),
                thumbnail: e['thumbnail_base64'],
                caption: e['caption'],
              ),
            )
            .toList();
    await mediaBox.addAll(files);
    setState(() {});
  }

  Future<void> _uploadFileWithType(XFile file) async {
    await loginService.uploadFile(file, context);
    await Future.delayed(const Duration(seconds: 1));
    await fetchFilesFromBackend();
  }

  Future<void> _uploadImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) await _uploadFileWithType(picked);
  }

  Future<void> _uploadVideo() async {
    final XFile? picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) await _uploadFileWithType(picked);
  }

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      await _uploadFileWithType(XFile(path));
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTab = MediaType.values[index];
    });
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text("Upload Photo"),
                  onTap: () {
                    Navigator.pop(context);
                    _uploadImage();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.video_collection),
                  title: const Text("Upload Video"),
                  onTap: () {
                    Navigator.pop(context);
                    _uploadVideo();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: const Text("Upload File (Docs, APKs, Others)"),
                  onTap: () {
                    Navigator.pop(context);
                    _uploadFile();
                  },
                ),
              ],
            ),
          ),
    );
  }

  List<UploadedFile> _getFilteredFiles() {
    final all = mediaBox.values.toList();

    final filteredByCaption = all.where((file) {
      return file.caption?.trim() == "uploaded via zerolimit";
    }).toList();

    return filteredByCaption.where((file) {
      switch (_selectedTab) {
        case MediaType.photos:
          return file.type == 'photo';
        case MediaType.videos:
          return file.type == 'video';
        case MediaType.docs:
          return file.type == 'doc' || file.type == 'document';
        case MediaType.apks:
          return file.name.toLowerCase().endsWith('.apk');
        case MediaType.others:
          return !(file.type == 'photo' || file.type == 'video' || file.type == 'doc' || file.name.toLowerCase().endsWith('.apk'));
      }
    }).toList();
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return "$bytes B";
    final kb = bytes / 1024;
    if (kb < 1024) return "${kb.toStringAsFixed(1)} KB";
    return "${(kb / 1024).toStringAsFixed(1)} MB";
  }

  Widget _buildFileGrid() {
    final files = _getFilteredFiles();

    if (files.isEmpty) {
      return const Center(child: Text("No files uploaded yet."));
    }

    return GridView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];

        return Card(
          elevation: 4,
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child:
                      (file.thumbnail != null && file.thumbnail!.isNotEmpty)
                          ? Builder(
                            builder: (context) {
                              try {
                                final safePreview = file.thumbnail!.substring(
                                  0,
                                  file.thumbnail!.length.clamp(0, 30),
                                );
                                print(
                                  "Thumbnail for ${file.name}: $safePreview...",
                                );
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(
                                    base64Decode(file.thumbnail!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print(
                                        "Error rendering image for ${file.name}: $error",
                                      );
                                      return const Icon(
                                        Icons.broken_image,
                                        size: 80,
                                        color: Colors.white70,
                                      );
                                    },
                                  ),
                                );
                              } catch (e) {
                                print(
                                  "Thumbnail decode failed for ${file.name}: $e",
                                );
                                return _buildFallbackIcon(file.type);
                              }
                            },
                          )
                          : _buildFallbackIcon(file.type),
                ),
                const SizedBox(height: 8),
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  formatFileSize(file.size),
                  style: const TextStyle(color: Colors.white60),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          LoginService().downloadMedia(
                            context: context,
                            fileId: file.fileId,
                            fileName: file.name,
                            type: file.type ?? 'other',
                            onProgress: (received, total) {},
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
                          LoginService().viewMedia(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(244, 225, 102, 1.0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Center(
          child: Text(
            _selectedTab.name.toUpperCase(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Color.fromRGBO(0, 0, 0, 1.0),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      body: _buildFileGrid(),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: _showFabNotifier,
        builder: (context, showFab, child) {
          return AnimatedSlide(
            offset: showFab ? Offset.zero : const Offset(0, 2),
            duration: const Duration(milliseconds: 300),
            child: AnimatedOpacity(
              opacity: showFab ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: FloatingActionButton.extended(
                onPressed: _showUploadOptions,
                label: const Text(
                  'Upload',
                  style: TextStyle(color: Color.fromRGBO(0, 0, 0, 1.0),
                  ),
                ),
                icon: const Icon(
                  Icons.upload,
                  color: Color.fromRGBO(0, 0, 0, 1.0),
                ),
                backgroundColor: const Color.fromRGBO(244, 225, 102, 1.0),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Color.fromRGBO(244, 225, 102, 1.0),
        selectedItemColor: Color.fromRGBO(191, 107, 207, 1.0),
        unselectedItemColor: Color.fromRGBO(0, 0, 0, 1.0),
        currentIndex: _selectedTab.index,
        onTap: _onTabSelected,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'Photos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Videos',
          ),
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
