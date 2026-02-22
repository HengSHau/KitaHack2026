import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // 浅灰色的背景，让白色卡片更凸显
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28, // 大标题风格
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false, // 标题靠左
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            // 加一点淡淡的阴影，提升质感
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSettingButton('Edit Profile', () {
                // TODO: 点击编辑资料
              }),
              const SizedBox(height: 16),
              _buildSettingButton('Feedback', () {
                // TODO: 点击反馈
              }),
              const SizedBox(height: 16),
              _buildSettingButton('Help Center', () {
                // TODO: 点击帮助中心
              }),
            ],
          ),
        ),
      ),
    );
  }

  // 统一的灰色按钮样式
  Widget _buildSettingButton(String title, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[400], // 设计图里的灰色
          foregroundColor: Colors.white,     // 文字颜色
          elevation: 0, // 去掉按钮自带的阴影，保持扁平
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // 稍微圆角
          ),
        ),
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}