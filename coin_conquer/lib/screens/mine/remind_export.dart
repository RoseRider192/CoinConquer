import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class RemindExportScreen extends StatefulWidget {
  const RemindExportScreen({super.key});

  @override
  State<RemindExportScreen> createState() => _RemindExportScreenState();
}

class _RemindExportScreenState extends State<RemindExportScreen> {
  bool _remindEnabled = false;
  String _remindPeriod = 'monthly';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('定期提醒导出'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('定期提醒导出'),
              subtitle: const Text('开启后定期提醒您备份数据'),
              value: _remindEnabled,
              onChanged: (v) => setState(() => _remindEnabled = v),
              activeColor: AppColors.primary,
            ),
          ),
          if (_remindEnabled) ...[
            Card(
              child: ListTile(
                title: const Text('提醒周期'),
                subtitle: Text({
                  'monthly': '每月提醒一次',
                  'quarterly': '每季度提醒一次',
                }[_remindPeriod] ?? ''),
                trailing: DropdownButton<String>(
                  value: _remindPeriod,
                  items: const [
                    DropdownMenuItem(value: 'monthly', child: Text('每月')),
                    DropdownMenuItem(value: 'quarterly', child: Text('每季度')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _remindPeriod = v);
                  },
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          _buildTutorialSection(),
        ],
      ),
    );
  }

  Widget _buildTutorialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text('如何导入数据恢复？', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 16),
              _TutorialStep(
                step: '1',
                title: '导出备份',
                description: '进入「我的」→「导出数据备份(JSON)」，将数据导出为JSON文件，保存到手机或发送到电脑。',
              ),
              _TutorialStep(
                step: '2',
                title: '换手机后安装App',
                description: '在新手机上安装CoinConquer，打开App。',
              ),
              _TutorialStep(
                step: '3',
                title: '导入数据',
                description: '进入「我的」→「导入数据恢复」，选择之前导出的JSON备份文件。',
              ),
              _TutorialStep(
                step: '4',
                title: '冲突检测',
                description: '如果导入的数据与已有数据日期重叠，系统会自动弹窗提醒，你可选择「先备份当前数据再导入」、「直接覆盖」或「取消」。',
              ),
              _TutorialStep(
                step: '5',
                title: '数据恢复完成',
                description: '导入成功后，所有历史记录、兼职信息、预算设置和周期性账单将完整恢复。',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TutorialStep extends StatelessWidget {
  final String step;
  final String title;
  final String description;

  const _TutorialStep({
    required this.step,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
