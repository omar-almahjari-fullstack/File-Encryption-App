import 'package:flutter/material.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'encrypt_screen.dart';
import 'decrypt_screen.dart';
import 'file_model.dart';
import 'file_manager.dart';
import 'app_colors.dart';
import 'file_card.dart';
import 'encrypt_screen.dart';
import 'decrypt_screen.dart';
import 'watermark_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FileManager _fileManager = FileManager();
  late Future<List<EncryptedFile>> _allFilesFuture;
  int _selectedCategoryIndex = 0;
  int _currentPage = 0;
  final PageController _pageController = PageController();
  
  final List<Map<String, dynamic>> _categories = [
    {'name': 'الكل', 'icon': Icons.all_inclusive, 'type': null},
    {'name': 'الفيديو', 'icon': Icons.videocam, 'type': FileType.video},
    {'name': 'الصور', 'icon': Icons.photo, 'type': FileType.image},
    {'name': 'المستندات', 'icon': Icons.description, 'type': FileType.document},
    {'name': 'الصوتيات', 'icon': Icons.audiotrack, 'type': FileType.audio},
    {'name': 'أخرى', 'icon': Icons.insert_drive_file, 'type': FileType.other},
  ];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  void _loadFiles() {
    _allFilesFuture = _fileManager.getAllFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: _buildAppBar(),
        drawer: _currentPage == 0 ? _buildDrawer() : null,
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildHomePage(),
            _buildEncryptPage(),
            _buildDecryptPage(),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildHomePage() {
    return Stack(
      children: [
        Column(
          children: [
            _buildCategoryBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _loadFiles();
                  });
                },
                child: FutureBuilder<List<EncryptedFile>>(
                  future: _allFilesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingView();
                    }

                    if (snapshot.hasError) {
                      return _buildErrorView(snapshot.error.toString());
                    }

                    if (snapshot.data == null || snapshot.data!.isEmpty) {
                      return _buildEmptyView();
                    }

                    List<EncryptedFile> filteredFiles = snapshot.data!;
                    if (_selectedCategoryIndex > 0) {
                      final selectedType = _categories[_selectedCategoryIndex]['type'];
                      if (selectedType != null) {
                        filteredFiles = snapshot.data!.where((file) {
                          return file.originalType == selectedType;
                        }).toList();
                      }
                    }

                    if (filteredFiles.isEmpty) {
                      return _buildEmptyCategoryView();
                    }

                    return _buildFilesGrid(filteredFiles);
                  },
                ),
              ),
            ),
          ],
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0.03,
            child: Center(
              child: Container(
                width: 300,
                height: 300,
                child: Image.network(
                  'assets/images/watermark_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.security,
                      size: 150,
                      color: Colors.grey[400],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEncryptPage() {
  return EncryptScreen();
   }
  Widget _buildDecryptPage() {
  return DecryptScreen(
                          fileName: '', // يمكنك تمرير اسم الملف المناسب هنا
                          initialFilePath: '', // يمكنك تمرير مسار الملف المناسب هنا
                        );
   }

  Widget _buildPageHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildNavCard(
              icon: Icons.folder_rounded,
              label: 'ملفاتي',
              isActive: _currentPage == 0,
              onTap: () => _goToPage(0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Material(
                elevation: 5,
                borderRadius: BorderRadius.circular(20),
                shadowColor: AppColors.primary.withOpacity(0.3),
                child: InkWell(
                  onTap: () => _goToPage(1),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 65,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'تشفير ملف',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildNavCard(
              icon: Icons.lock_open_rounded,
              label: 'فك التشفير',
              isActive: _currentPage == 2,
              onTap: () => _goToPage(2),
            ),
          ),
        ],
      ),
    );
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildNavCard({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(15),
            border: isActive
                ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: isActive ? AppColors.primary : Colors.grey.shade700,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? AppColors.primary : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          const Icon(Icons.security, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Text(
            _currentPage == 0 
              ? 'تشفير الملفات' 
              : (_currentPage == 1 ? 'تشفير ملف' : 'فك التشفير'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.primary,
      centerTitle: false,
      elevation: 2,
      leading: _currentPage == 0 
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            )
          : IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => _goToPage(0),
            ),
      actions: _currentPage == 0 
          ? [
              FutureBuilder<List<EncryptedFile>>(
                future: _allFilesFuture,
                builder: (context, snapshot) {
                  int fileCount = snapshot.hasData ? snapshot.data!.length : 0;
                  return Container(
                    margin: const EdgeInsets.only(left: 8, top: 12, bottom: 12, right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.folder, size: 18, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          '$fileCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 26),
                onPressed: () {
                  setState(() {
                    _loadFiles();
                  });
                  _showMessage('تم تحديث الملفات', AppColors.success);
                },
                tooltip: 'تحديث',
              ),
            ]
          : null,
    );
  }

  Widget _buildCategoryBar() {
    return FutureBuilder<List<EncryptedFile>>(
      future: _allFilesFuture,
      builder: (context, snapshot) {
        Map<FileType, int> typeCounts = {
          FileType.video: 0,
          FileType.image: 0,
          FileType.document: 0,
          FileType.audio: 0,
          FileType.other: 0,
        };
        
        if (snapshot.hasData) {
          for (var file in snapshot.data!) {
            typeCounts[file.originalType] = (typeCounts[file.originalType] ?? 0) + 1;
          }
        }
        
        return Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = index == _selectedCategoryIndex;
              int count = 0;
              
              if (index == 0) {
                count = snapshot.hasData ? snapshot.data!.length : 0;
              } else if (category['type'] != null) {
                count = typeCounts[category['type']] ?? 0;
              }
              
              return _buildCategoryChip(
                category: category,
                isSelected: isSelected,
                count: count,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip({
    required Map<String, dynamic> category,
    required bool isSelected,
    required int count,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryIndex = _categories.indexOf(category);
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              category['icon'],
              color: isSelected ? Colors.white : Colors.grey[700],
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              category['name'],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.3) : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(
                      Icons.lock,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'تشفير الملفات',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'حماية كاملة للملفات',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 15),
                  FutureBuilder<List<EncryptedFile>>(
                    future: _allFilesFuture,
                    builder: (context, snapshot) {
                      int totalFiles = snapshot.hasData ? snapshot.data!.length : 0;
                      int totalSize = 0;
                      if (snapshot.hasData) {
                        for (var file in snapshot.data!) {
                          totalSize += file.size;
                        }
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDrawerStat('الملفات', '$totalFiles', Icons.folder),
                          _buildDrawerStat('الحجم', _formatSize(totalSize), Icons.storage),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.lock,
                    title: 'تشفير جديد',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _goToPage(1);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.lock_open,
                    title: 'فك التشفير',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      _goToPage(2);
                    },
                  ),
                  const Divider(height: 20),
                  _buildDrawerItem(
                    icon: Icons.security,
                    title: 'الأمان والتشفير',
                    subtitle: 'AES-256 | مستوى عالي',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _showSecurityDialog();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.help,
                    title: 'المساعدة',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      _showHelpDialog();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.info,
                    title: 'حول التطبيق',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutDialog();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings,
                    title: 'الإعدادات',
                    color: Colors.grey,
                    onTap: () {
                      Navigator.pop(context);
                      _showSettingsDialog();
                    },
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Column(
                children: [
                  Text(
                    'جميع الحقوق محفوظة © 2026\neng: Omar AL-mahjari\n+967 774360827',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'الإصدار 2.0.0',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_left, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildFilesGrid(List<EncryptedFile> filteredFiles) {
    if (filteredFiles.isEmpty) {
      return _buildEmptyCategoryView();
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: filteredFiles.length,
      itemBuilder: (context, index) {
        final file = filteredFiles[index];
        return FileCard(
          file: file,
          onTap: () => _showFileOptions(file),
        );
      },
    );
  }

  void _showFileOptions(EncryptedFile file) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: ListView(
            shrinkWrap: true,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                    _getFileIcon(file.originalType),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name.length > 30 
                              ? '${file.name.substring(0, 30)}...' 
                              : file.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatSize(file.size)} • ${_formatDate(file.encryptionDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
                _buildOption(
                  Icons.lock_open,
                  'فك التشفير',
                  'فتح الملف المشفر',
                  Colors.blue,
                  () {
                    Navigator.pop(context);
                    _navigateToDecryptScreen(file);
                  },
                ),
                _buildOption(
                  Icons.share,
                  'مشاركة',
                  'مشاركة الملف المشفر',
                  Colors.green,
                  () {
                    Navigator.pop(context);
                    _shareFile(file);
                  },
                ),
                _buildOption(
                  Icons.open_in_new,
                  'فتح الموقع',
                  'فتح مجلد الملف',
                  Colors.orange,
                  () {
                    Navigator.pop(context);
                    _openFileLocation(file);
                  },
                ),
                _buildOption(
                  Icons.info_outline,
                  'تفاصيل',
                  'عرض معلومات الملف',
                  Colors.purple,
                  () {
                    Navigator.pop(context);
                    _showFileDetails(file);
                  },
                ),
                _buildOption(
                  Icons.delete,
                  'حذف',
                  'حذف الملف نهائياً',
                  Colors.red,
                  () {
                    Navigator.pop(context);
                    _deleteFile(file);
                  },
                  isDestructive: true,
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إغلاق'),
                  ),
                ),
              ],
            ),
          ]),
        );
      },
    );
  }

  Widget _getFileIcon(FileType type) {
    IconData icon;
    Color color;
    
    switch (type) {
      case FileType.video:
        icon = Icons.videocam;
        color = Colors.red;
        break;
      case FileType.image:
        icon = Icons.photo;
        color = Colors.blue;
        break;
      case FileType.document:
        icon = Icons.description;
        color = Colors.green;
        break;
      case FileType.audio:
        icon = Icons.audiotrack;
        color = Colors.purple;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildOption(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : color,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.grey,
        ),
      ),
      trailing: const Icon(Icons.chevron_left, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildLoadingView() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            const Text(
              'لا توجد ملفات مشفرة',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'ابدأ بتشفير ملفاتك الأولى للحفاظ على أمانها وسريتها',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => _goToPage(1),
              icon: const Icon(Icons.leak_add, size: 22),
              label: const Text(
                'ابدأ التشفير الآن',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCategoryView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _categories[_selectedCategoryIndex]['icon'],
            size: 70,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          const Text(
            'لا توجد ملفات في هذا التصنيف',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'حاول تشفير ملفات من هذا النوع',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 60,
          ),
          const SizedBox(height: 16),
          const Text(
            'خطأ في تحميل الملفات',
            style: TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _loadFiles();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  void _showFileDetails(EncryptedFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفاصيل الملف'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('الاسم الحالي:', file.name),
              _buildDetailRow('الاسم الأصلي:', file.originalName),
              _buildDetailRow('نوع الملف:', FileTypeInfo.getName(file.originalType)),
              _buildDetailRow('الحجم:', _formatSize(file.size)),
              _buildDetailRow('تاريخ التشفير:', _formatDate(file.encryptionDate)),
              _buildDetailRow('المسار:', file.path),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDecryptScreen(EncryptedFile file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DecryptScreen(
          initialFile: file, 
          fileName: file.name, 
          initialFilePath: file.path,
        ),
      ),
    );
  }

  Future<void> _shareFile(EncryptedFile file) async {
    try {
      final fileToShare = XFile(file.path);
      await Share.shareXFiles([fileToShare]);
    } catch (e) {
      _showMessage('خطأ في مشاركة الملف: $e', AppColors.error);
    }
  }

  Future<void> _openFileLocation(EncryptedFile file) async {
    try {
      final directory = File(file.path).parent;
      if (await directory.exists()) {
        OpenFile.open(directory.path);
      } else {
        _showMessage('المجلد غير موجود', AppColors.warning);
      }
    } catch (e) {
      _showMessage('خطأ في فتح الموقع', AppColors.error);
    }
  }

  Future<void> _deleteFile(EncryptedFile file) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الملف'),
        content: Text('هل أنت متأكد من حذف "${file.name}"؟\n\nهذا الإجراء لا يمكن التراجع عنه.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await File(file.path).delete();
        _showMessage('تم حذف الملف بنجاح', AppColors.success);
        setState(() {
          _loadFiles();
        });
      } catch (e) {
        _showMessage('خطأ في حذف الملف: $e', AppColors.error);
      }
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes بايت';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} كيلوبايت';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} ميجابايت';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} جيجابايت';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // النوافذ المنبثقة
  void _showSecurityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.blue, size: 28),
            SizedBox(width: 10),
            Text('الأمان والتشفير'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSecurityFeature('🔒', 'AES-256 CBC', 'تشفير عسكري المستوى'),
              _buildSecurityFeature('🛡️', 'IV عشوائي', 'مفتاح تهيئة عشوائي لكل ملف'),
              _buildSecurityFeature('🔑', 'مفتاح 256 بت', 'مفتاح تشفير قوي وآمن'),
              _buildSecurityFeature('📱', 'دون اتصال', 'لا يتطلب اتصال بالإنترنت'),
              _buildSecurityFeature('🚫', 'لا سحابة', 'بياناتك تبقى على جهازك'),
              const SizedBox(height: 15),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                'نصائح أمنية مهمة:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 8),
              const Text('• احفظ مفتاح التشفير في مكان آمن'),
              const Text('• لا تشارك المفتاح مع أحد'),
              const Text('• احتفظ بنسخة احتياطية من المفاتيح'),
              const Text('• استخدم مفتاحاً مختلفاً لكل ملف مهم'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFeature(String emoji, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help, color: Colors.purple, size: 28),
            SizedBox(width: 10),
            Text('المساعدة والدعم'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpSection('📁', 'كيفية التشفير', [
                '1. اختر أي ملف من جهازك',
                '2. أدخل مفتاح التشفير (8 أحرف على الأقل)',
                '3. اضغط على زر "تشفير الملف"',
                '4. احفظ الملف المشفر في المجلد المطلوب',
              ]),
              _buildHelpSection('🔓', 'كيفية فك التشفير', [
                '1. اختر ملف .enc المشفر',
                '2. أدخل نفس مفتاح التشفير المستخدم سابقاً',
                '3. اضغط على زر "فك التشفير"',
                '4. سيتم حفظ الملف المفكوك في مجلد Decrypted_files',
              ]),
              _buildHelpSection('⚠️', 'مشاكل شائعة', [
                '• تذكر المفتاح: فقدانه يعني فقدان الملف',
                '• تأكد من تطابق المفاتيح',
                '• الملفات الكبيرة تستغرق وقتاً أطول',
                '• تأكد من صلاحيات التخزين',
              ]),
              const SizedBox(height: 15),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                'للتواصل والدعم:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('📧 البريد: smartdeals763@gmail.com'),
              const Text('📱 الواتساب:774360827 967+ '),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String icon, String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text('• $item'),
          )),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.teal, size: 28),
            SizedBox(width: 10),
            Text('حول التطبيق'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.teal[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock,
                    size: 40,
                    color: Colors.teal,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'تطبيق تشفير الملفات الآمن',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                'المميزات الرئيسية:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildFeatureItem('تشفير AES-256 عالي الأمان'),
              _buildFeatureItem('دعم جميع أنواع الملفات'),
              _buildFeatureItem('واجهة عربية كاملة'),
              _buildFeatureItem('يعمل دون اتصال بالإنترنت'),
              _buildFeatureItem('تنظيم الملفات حسب النوع'),
              const SizedBox(height: 15),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                'معلومات التقنية:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('الإصدار: 2.0.0'),
              const Text('تاريخ الإصدار: يناير 2024'),
              const Text('المطور: فريق التشفير'),
              const Text('الترخيص: MIT Open Source'),
              const SizedBox(height: 15),
              const Center(
                child: Text(
                  'شكراً لاستخدامك تطبيقنا!',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.teal, size: 16),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    bool notifications = true;
    bool autoBackup = false;
    bool darkMode = false;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.settings, color: Colors.grey, size: 28),
                  SizedBox(width: 10),
                  Text('الإعدادات'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: const Text('الإشعارات'),
                      subtitle: const Text('إشعارات عند اكتمال التشفير'),
                      value: notifications,
                      onChanged: (value) => setState(() => notifications = value),
                    ),
                    SwitchListTile(
                      title: const Text('نسخ احتياطي تلقائي'),
                      subtitle: const Text('نسخ الملفات المشفرة تلقائياً'),
                      value: autoBackup,
                      onChanged: (value) => setState(() => autoBackup = value),
                    ),
                    SwitchListTile(
                      title: const Text('الوضع الداكن'),
                      subtitle: const Text('تفعيل الوضع الداكن'),
                      value: darkMode,
                      onChanged: (value) => setState(() => darkMode = value),
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                    const SizedBox(height: 10),
                    ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text('مسح ذاكرة التخزين المؤقت'),
                      onTap: () {
                        Navigator.pop(context);
                        _showMessage('تم مسح ذاكرة التخزين المؤقت', AppColors.success);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.update, color: Colors.blue),
                      title: const Text('تحديث قائمة الملفات'),
                      onTap: () {
                        Navigator.pop(context);
                        _showMessage('تم تحديث الملفات', AppColors.success);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showMessage('تم حفظ الإعدادات', AppColors.success);
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}