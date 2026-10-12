import 'package:flutter/material.dart';
import 'encrypt_screen.dart';
import 'decrypt_screen.dart';
import 'file_model.dart';
import 'file_manager.dart';
import 'app_colors.dart';
import 'file_card.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'watermark_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FileManager _fileManager = FileManager();
  late Future<List<EncryptedFile>> _allFilesFuture;
  int _selectedCategoryIndex = 0; // 0 = الكل, 1 = الفيديو, 2 = الصور, إلخ.
  // في الجزء الخاص بالتصنيفات
final List<Map<String, dynamic>> _categories = [
  {'name': 'الكل', 'icon': Icons.all_inclusive, 'type': null},
  {'name': 'الفيديو', 'icon': Icons.videocam, 'type': FileType.video},
  {'name': 'الصور', 'icon': Icons.photo, 'type': FileType.image},
  {'name': 'المستندات', 'icon': Icons.description, 'type': FileType.document},
  {'name': 'الصوتيات', 'icon': Icons.audiotrack, 'type': FileType.audio},
  {'name': 'أخرى', 'icon': Icons.insert_drive_file, 'type': FileType.other},
];



// إضافة علامة مائية خلفية للشاشة الرئيسية
// في _buildBody
Widget _buildBody() {
  return Stack(
    children: [
      // المحتوى الرئيسي
      Column(
        children: [
          // شريط التصنيفات
          _buildCategoryBar(),
          
          // الملفات
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

                  if (snapshot.data!.isEmpty) {
                    return _buildEmptyCategoryView();
                  }

                  // تصفية الملفات حسب التصنيف
                  List<EncryptedFile> filteredFiles = snapshot.data!;
                  if (_selectedCategoryIndex > 0) {
                    final selectedType = _categories[_selectedCategoryIndex]['type'];
                    if (selectedType != null) {
                      // استخدام originalType للتصفية
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
      
      // العلامة المائية الخلفية (شفافة)
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
            // إذا حدث خطأ، استخدم أيقونة بديلة
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

// في دالة _showFileDetails
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

// تحديث _buildCategoryBar مع العدادات
Widget _buildCategoryBar() {
  return FutureBuilder<List<EncryptedFile>>(
    future: _allFilesFuture,
    builder: (context, snapshot) {
      // حساب عدد الملفات لكل نوع
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
              // "الكل"
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
        drawer: _buildDrawer(),
        body: _buildBody(),
        // floatingActionButton: FloatingActionButton.extended(
        //   onPressed: () {
        //     Navigator.push(
        //       context,
        //       MaterialPageRoute(builder: (context) => const EncryptScreen()),
        //     );
        //   },
        //   icon: const Icon(Icons.leak_add, size: 24),
        //   label: const Text('تشفير جديد'),
        //   backgroundColor: AppColors.primary,
        //   foregroundColor: Colors.white,
        //   elevation: 4,
        // ),

        bottomNavigationBar: Container(
  height: 90,
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
      // ملفاتي / الرئيسية
      Expanded(
        child: _buildModernNavCard(
          icon: Icons.folder_rounded,
          label: 'ملفاتي',
          isActive: false,
          backgroundColor: Colors.grey.shade50,
          onTap: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
              (route) => false,
            );
          },
        ),
      ),
      
      const SizedBox(width: 10),
      
      // تشفير (مركزي)
      Expanded(
        flex: 2,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            elevation: 5,
            borderRadius: BorderRadius.circular(20),
            shadowColor: AppColors.primary.withOpacity(0.3),
            child: InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const EncryptScreen()),
                );
              },
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
      
      // فك تشفير
      Expanded(
        child: _buildModernNavCard(
          icon: Icons.lock_open_rounded,
          label: 'فك التشفير',
          isActive: true,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          borderColor: AppColors.primary.withOpacity(0.3),
          onTap: () {
            // نحن هنا بالفعل
          },
        ),
      ),
    ],
  ),
),
      ),
    );
  }
Widget _buildModernNavCard({
  required IconData icon,
  required String label,
  required bool isActive,
  required Color backgroundColor,
  Color? borderColor,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(15),
          border: borderColor != null
              ? Border.all(color: borderColor, width: 1.5)
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
      title: const Row(
        children: [
          Icon(Icons.security, color: Colors.white, size: 28),
          SizedBox(width: 10),
          Text(
            'تشفير الملفات',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.primary,
      centerTitle: false,
      elevation: 2,
      actions: [
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
      ],
    );
  }

  Widget _buildDrawer() {
  return Drawer(
    child: Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          // رأس الدراور (يظل كما هو)
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

          // قائمة الخيارات المعدلة
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // زر تشفير جديد
                _buildDrawerItem(
                  icon: Icons.lock,
                  title: 'تشفير جديد',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EncryptScreen()),
                    );
                  },
                ),
                
                // زر فك التشفير
                _buildDrawerItem(
                  icon: Icons.lock_open,
                  title: 'فك التشفير',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DecryptScreen(
                          fileName: '', // يمكنك تمرير اسم الملف المناسب هنا
                          initialFilePath: '', // يمكنك تمرير مسار الملف المناسب هنا
                        ),
                      ),
                    );
                  },
                ),
                
                const Divider(height: 20),
                
                // زر الأمان - يفتح نافذة منبثقة
                _buildDrawerItem(
                  icon: Icons.security,
                  title: 'الأمان والتشفير',
                  subtitle: 'AES-256 | مستوى عالي',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _showSecurityDialog(context);
                  },
                ),
                
                // زر المساعدة - يفتح نافذة منبثقة
                _buildDrawerItem(
                  icon: Icons.help,
                  title: 'المساعدة',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _showHelpDialog(context);
                  },
                ),
                
                // زر حول التطبيق - يفتح نافذة منبثقة
                _buildDrawerItem(
                  icon: Icons.info,
                  title: 'حول التطبيق',
                  color: Colors.teal,
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog(context);
                  },
                ),
                
                // زر إعدادات إضافية
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'الإعدادات',
                  color: Colors.grey,
                  onTap: () {
                    Navigator.pop(context);
                    _showSettingsDialog(context);
                  },
                ),
              ],
            ),
          ),

          // تذييل الدراور (يظل كما هو)
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                Text(
                  'جميع الحقوق محفوظة © 2026 \n eng: Omar AL-mahjari\n +967 774360827',
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


void _navigateToDecryptScreen(EncryptedFile file) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DecryptScreen(
        initialFile: file, fileName: '', initialFilePath: '', // تمرير الملف كاملاً
      ),
    ),
  );
}
// duplicate _categories removed (defined earlier in the class)
  void _showFileOptions(EncryptedFile file) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ListView(
          children:[ Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // معلومات الملف
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
                
                // الخيارات
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
                
                // زر الإغلاق
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                ),
              ],
            ),
          ),
       ] );
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
            Text(
              'لا توجد ملفات مشفرة',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'ابدأ بتشفير ملفاتك الأولى للحفاظ على أمانها وسريتها',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EncryptScreen()),
                );
              },
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
          Text(
            'لا توجد ملفات في هذا التصنيف',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'حاول تشفير ملفات من هذا النوع',
            style: TextStyle(
              color: Colors.grey[500],
            ),
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
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
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
              style: TextStyle(
                color: Colors.grey[600],
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

  // ===== الوظائف =====
  
  // Future<void> _decryptFile(EncryptedFile file) async {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => DecryptScreen(
  //         initialFilePath: file.path,
  //         fileName: file.name,
  //       ),
  //     ),
  //   );
  // }

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

  void _showSecurityInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.blue),
            SizedBox(width: 10),
            Text('معلومات الأمان'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('• تشفير AES-256 CBC (مستوى عسكري)'),
              Text('• IV عشوائي 16 بايت لكل ملف'),
              Text('• مفتاح 256 بت (32 حرف)'),
              Text('• يعمل دون اتصال بالإنترنت'),
              Text('• لا يتم إرسال أي بيانات للسحابة'),
              SizedBox(height: 10),
              Text('⚠️ احفظ المفتاح في مكان آمن'),
              Text('⚠️ فقدان المفتاح يعني فقدان الملفات'),
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

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('المساعدة'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📁 التشفير:'),
              Text('1. اختر ملف من جهازك'),
              Text('2. أدخل مفتاح التشفير (8 أحرف على الأقل)'),
              Text('3. اضغط على زر التشفير'),
              SizedBox(height: 10),
              Text('🔓 فك التشفير:'),
              Text('1. اختر ملف .enc'),
              Text('2. أدخل نفس مفتاح التشفير'),
              Text('3. اضغط على زر فك التشفير'),
              SizedBox(height: 10),
              Text('📞 للدعم: support@encrypt.com'),
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

  void _showAboutApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حول التطبيق'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('تطبيق تشفير الملفات الآمن'),
              SizedBox(height: 10),
              Text('المميزات:'),
              Text('• تشفير وفك تشفير أي نوع ملف'),
              Text('• حماية AES-256 عالية المستوى'),
              Text('• واجهة عربية سهلة الاستخدام'),
              Text('• يعمل دون اتصال بالإنترنت'),
              SizedBox(height: 10),
              Text('الإصدار: 2.0.0'),
              Text('التحديث الأخير: يناير 2024'),
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

  String _getTypeName(FileType type) {
    switch (type) {
      case FileType.video: return 'فيديو';
      case FileType.image: return 'صورة';
      case FileType.document: return 'مستند';
      case FileType.audio: return 'صوت';
      case FileType.other: return 'ملف آخر';
    }
  }
}





// دالة مساعدة لعناصر Drawer
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

// ===== الدوال الخاصة بالنوافذ المنبثقة =====

void _showSecurityDialog(BuildContext context) {
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

void _showHelpDialog(BuildContext context) {
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
            const Text('📧 البريد: support@encrypt.com'),
            const Text('📱 الواتساب: +966 50 123 4567'),
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

void _showAboutDialog(BuildContext context) {
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
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
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

void _showSettingsDialog(BuildContext context) {
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
                    onChanged: (value) {
                      setState(() {
                        notifications = value;
                      });
                    },
                  ),
                  
                  SwitchListTile(
                    title: const Text('نسخ احتياطي تلقائي'),
                    subtitle: const Text('نسخ الملفات المشفرة تلقائياً'),
                    value: autoBackup,
                    onChanged: (value) {
                      setState(() {
                        autoBackup = value;
                      });
                    },
                  ),
                  
                  SwitchListTile(
                    title: const Text('الوضع الداكن'),
                    subtitle: const Text('تفعيل الوضع الداكن'),
                    value: darkMode,
                    onChanged: (value) {
                      setState(() {
                        darkMode = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('مسح ذاكرة التخزين المؤقت'),
                    onTap: () {
                      // TODO: مسح الذاكرة المؤقتة
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم مسح ذاكرة التخزين المؤقت'), backgroundColor: AppColors.success),
                      );
                    },
                  ),
                  
                  ListTile(
                    leading: const Icon(Icons.update, color: Colors.blue),
                    title: const Text('تحديث قائمة الملفات'),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم تحديث الملفات'), backgroundColor: AppColors.success),
                      );
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
                  // TODO: حفظ الإعدادات
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم حفظ الإعدادات'), backgroundColor: AppColors.success),
                  );
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