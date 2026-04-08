import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/fuel_record.dart';
import '../models/vehicle.dart';
import '../providers/fuel_provider.dart';
import '../providers/vehicle_provider.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_widget.dart';

class FuelScreen extends StatefulWidget {
  const FuelScreen({super.key});

  @override
  State<FuelScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends State<FuelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _vehicleFilterLabel = 'جميع السيارات';
  int? _selectedVehicleId;

  // ── Nolon calculator state ──
  final _weightController = TextEditingController();
  String _selectedGovernorate = '';
  int _nolonResult = 0;
  double _customRate = 0;

  // ── Built-in calculator state ──
  final _calcDisplay = TextEditingController();
  String _calcExpression = '';
  String _calcResult = '0';
  bool _calcHasResult = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _weightController.dispose();
    _calcDisplay.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final fuelProvider = context.read<FuelProvider>();
    final vehicleProvider = context.read<VehicleProvider>();
    if (vehicleProvider.allVehicles.isEmpty) {
      await vehicleProvider.loadVehicles();
    }
    await fuelProvider.loadFuelRecords();
  }

  // ═══════════════════════════════════════════════════════════════
  // Egyptian Governorates (27 governorates - complete)
  // ═══════════════════════════════════════════════════════════════

  /// Default rates for each governorate. User can change them manually.
  static Map<String, double> _governorateRates = {
    // القاهرة والجيزة
    'القاهرة': 1.0,
    'الجيزة': 1.0,
    // الدلتا والوجه البحري
    'القليوبية': 0.95,
    'المنوفية': 0.95,
    'الغربية': 0.95,
    'كفر الشيخ': 0.95,
    'الدقهلية': 0.95,
    'دمياط': 0.95,
    'الشرقية': 0.95,
    'البحيرة': 0.90,
    // القناة وسيناء
    'الإسماعيلية': 0.90,
    'بورسعيد': 0.90,
    'السويس': 0.90,
    'شمال سيناء': 0.85,
    'جنوب سيناء': 0.85,
    // الإسكندرية
    'الإسكندرية': 0.95,
    // الصعيد (الوجه القبلي)
    'الفيوم': 0.90,
    'بني سويف': 0.90,
    'المنيا': 0.85,
    'أسيوط': 0.85,
    'سوهاج': 0.80,
    'قنا': 0.80,
    'الأقصر': 0.75,
    'أسوان': 0.75,
    // المحافظات الحدودية
    'البحر الأحمر': 0.80,
    'الوادي الجديد': 0.70,
    'مطروح': 0.80,
  };

  static const List<String> _governorateGroups = [
    'القاهرة والجيزة',
    'الإسكندرية',
    'الوجه البحري (الدلتا)',
    'القناة وسيناء',
    'الصعيد (الوجه القبلي)',
    'المحافظات الحدودية',
  ];

  List<String> _getGovernoratesInGroup(String group) {
    switch (group) {
      case 'القاهرة والجيزة':
        return ['القاهرة', 'الجيزة'];
      case 'الإسكندرية':
        return ['الإسكندرية'];
      case 'الوجه البحري (الدلتا)':
        return ['القليوبية', 'المنوفية', 'الغربية', 'كفر الشيخ', 'الدقهلية', 'دمياط', 'الشرقية', 'البحيرة'];
      case 'القناة وسيناء':
        return ['الإسماعيلية', 'بورسعيد', 'السويس', 'شمال سيناء', 'جنوب سيناء'];
      case 'الصعيد (الوجه القبلي)':
        return ['الفيوم', 'بني سويف', 'المنيا', 'أسيوط', 'سوهاج', 'قنا', 'الأقصر', 'أسوان'];
      case 'المحافظات الحدودية':
        return ['البحر الأحمر', 'الوادي الجديد', 'مطروح'];
      default:
        return [];
    }
  }

  void _calculateNolon() {
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0 || _selectedGovernorate.isEmpty) {
      setState(() => _nolonResult = 0);
      return;
    }
    final rate = _customRate > 0 ? _customRate : (_governorateRates[_selectedGovernorate] ?? 0.8);
    final tonnage = weight / 1000;
    setState(() {
      _nolonResult = (tonnage * rate * 50).round();
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILT-IN CALCULATOR
  // ═══════════════════════════════════════════════════════════════

  void _calcInput(String value) {
    setState(() {
      if (_calcHasResult && value != 'C' && !['+', '-', '×', '÷'].contains(value)) {
        _calcExpression = '';
        _calcResult = '0';
        _calcHasResult = false;
      }
      _calcHasResult = false;
      if (value == 'C') {
        _calcExpression = '';
        _calcResult = '0';
      } else if (value == '⌫') {
        if (_calcExpression.isNotEmpty) {
          _calcExpression = _calcExpression.substring(0, _calcExpression.length - 1);
        }
        if (_calcExpression.isEmpty) _calcResult = '0';
      } else if (value == '=') {
        _calcResult = _evaluateExpression(_calcExpression);
        _calcHasResult = true;
      } else {
        _calcExpression += value;
      }
      _calcDisplay.text = _calcHasResult ? _calcResult : _calcExpression;
    });
  }

  String _evaluateExpression(String expression) {
    try {
      if (expression.isEmpty) return '0';
      // Replace display operators with math operators
      String eval = expression.replaceAll('×', '*').replaceAll('÷', '/');

      // Parse and evaluate safely
      final result = _parseMath(eval);
      if (result == null || result.isInfinite || result.isNaN) return 'خطأ';
      // Format result
      if (result == result.truncateToDouble()) {
        return result.toInt().toString();
      }
      return result.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    } catch (e) {
      return 'خطأ';
    }
  }

  double? _parseMath(String expr) {
    // Simple math parser supporting +, -, *, / with proper precedence
    expr = expr.replaceAll(' ', '');
    if (expr.isEmpty) return null;
    return _parseAddSub(expr, 0).$1;
  }

  (double?, int) _parseAddSub(String expr, int pos) {
    var (left, nextPos) = _parseMulDiv(expr, pos);
    if (left == null) return (null, nextPos);
    while (nextPos < expr.length) {
      final op = expr[nextPos];
      if (op != '+' && op != '-') break;
      nextPos++;
      var (right, newPos) = _parseMulDiv(expr, nextPos);
      if (right == null) return (null, newPos);
      final l = left!, r = right!;
      left = op == '+' ? l + r : l - r;
      nextPos = newPos;
    }
    return (left, nextPos);
  }

  (double?, int) _parseMulDiv(String expr, int pos) {
    var (left, nextPos) = _parseNumber(expr, pos);
    if (left == null) return (null, nextPos);
    while (nextPos < expr.length) {
      final op = expr[nextPos];
      if (op != '*' && op != '/') break;
      nextPos++;
      var (right, newPos) = _parseNumber(expr, nextPos);
      if (right == null) return (null, newPos);
      final l = left!, r = right!;
      if (op == '*') {
        left = l * r;
      } else {
        if (r == 0) return (double.nan, newPos);
        left = l / r;
      }
      nextPos = newPos;
    }
    return (left, nextPos);
  }

  (double?, int) _parseNumber(String expr, int pos) {
    // Handle unary minus
    if (pos < expr.length && expr[pos] == '-') {
      final (val, newPos) = _parseNumber(expr, pos + 1);
      return (val != null ? -val : null, newPos);
    }
    if (pos < expr.length && expr[pos] == '+') {
      return _parseNumber(expr, pos + 1);
    }
    // Handle parentheses
    if (pos < expr.length && expr[pos] == '(') {
      final (val, newPos) = _parseAddSub(expr, pos + 1);
      if (newPos < expr.length && expr[newPos] == ')') {
        return (val, newPos + 1);
      }
      return (null, newPos);
    }
    // Parse digits and decimal point
    final buffer = StringBuffer();
    while (pos < expr.length) {
      final ch = expr[pos];
      final code = ch.codeUnitAt(0);
      if ((code >= 48 && code <= 57) || ch == '.') {
        buffer.write(ch);
        pos++;
      } else {
        break;
      }
    }
    if (buffer.isEmpty) return (null, pos);
    return (double.tryParse(buffer.toString()), pos);
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ── Page Title ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                const Text(
                  'النولون + الوقود',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // ── Tabs ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppColors.textSecondary,
              unselectedLabelColor: AppColors.textHint,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'Cairo',
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Cairo',
              ),
              tabs: const [
                Tab(text: 'حساب النولون'),
                Tab(text: 'آلة حاسبة'),
                Tab(text: 'سجلات الوقود'),
              ],
            ),
          ),

          // ── Tab Content ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNolonTab(),
                _buildCalculatorTab(),
                _buildFuelTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 2
          ? FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/add-fuel'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // NOLON TAB
  // ═══════════════════════════════════════════════════════════════

  Widget _buildNolonTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Intro Card ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary.withOpacity(0.08), AppColors.primary.withOpacity(0.02)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calculate, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'حاسبة النولون',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'اختر المحافظة ووزن الحمولة لحساب تكلفة النولون • يمكنك تعديل النسبة يدوياً',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Governorate Selection ──
        _buildSectionTitle('المحافظة'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGovernorate.isEmpty ? null : _selectedGovernorate,
          decoration: const InputDecoration(
            labelText: 'اختر محافظة التوصيل',
            prefixIcon: Icon(Icons.location_city),
          ),
          items: _governorateRates.keys.map((gov) {
            final rate = _governorateRates[gov]!;
            return DropdownMenuItem(
              value: gov,
              child: Row(
                children: [
                  Text(gov),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getRateColor(rate).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${(rate * 100).round()}%',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _getRateColor(rate)),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedGovernorate = value ?? '';
              _customRate = 0;
            });
            _calculateNolon();
          },
        ),
        const SizedBox(height: 16),

        // ── Manual Rate Override ──
        _buildSectionTitle('نسبة النولون (يدوي)'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: TextEditingController(text: _customRate > 0 ? _customRate.toStringAsFixed(2) : ''),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  final parsed = double.tryParse(value.trim());
                  if (parsed != null && parsed >= 0 && parsed <= 2) {
                    setState(() => _customRate = parsed);
                    _calculateNolon();
                  } else if (value.trim().isEmpty) {
                    setState(() => _customRate = 0);
                    _calculateNolon();
                  }
                },
                decoration: InputDecoration(
                  labelText: 'اتركه فارغاً للنسبة الافتراضية',
                  prefixIcon: const Icon(Icons.percent),
                  suffixText: '%',
                  hintText: '${((_governorateRates[_selectedGovernorate] ?? 0) * 100).round()}%',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                setState(() {
                  _customRate = 0;
                  _calculateNolon();
                });
              },
              icon: const Icon(Icons.refresh),
              tooltip: 'إعادة النسبة الافتراضية',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Weight Input ──
        _buildSectionTitle('وزن الحمولة'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => _calculateNolon(),
          decoration: const InputDecoration(
            labelText: 'الوزن (كيلوجرام)',
            prefixIcon: Icon(Icons.scale),
            suffixText: 'كجم',
            hintText: 'أدخل وزن الحمولة',
          ),
        ),
        const SizedBox(height: 20),

        // ── Quick Weight Buttons ──
        _buildSectionTitle('أوزان سريعة'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QuickWeightBtn(label: 'طن', weight: 1000, onTap: () { _weightController.text = '1000'; _calculateNolon(); }),
            _QuickWeightBtn(label: '2 طن', weight: 2000, onTap: () { _weightController.text = '2000'; _calculateNolon(); }),
            _QuickWeightBtn(label: '3 طن', weight: 3000, onTap: () { _weightController.text = '3000'; _calculateNolon(); }),
            _QuickWeightBtn(label: '5 طن', weight: 5000, onTap: () { _weightController.text = '5000'; _calculateNolon(); }),
            _QuickWeightBtn(label: '10 طن', weight: 10000, onTap: () { _weightController.text = '10000'; _calculateNolon(); }),
            _QuickWeightBtn(label: '15 طن', weight: 15000, onTap: () { _weightController.text = '15000'; _calculateNolon(); }),
            _QuickWeightBtn(label: '20 طن', weight: 20000, onTap: () { _weightController.text = '20000'; _calculateNolon(); }),
          ],
        ),
        const SizedBox(height: 24),

        // ── Result Card ──
        _buildResultCard(),

        const SizedBox(height: 16),

        // ── Governorate Groups Reference ──
        _buildGovernorateReference(),
      ],
    );
  }

  Widget _buildResultCard() {
    final weight = double.tryParse(_weightController.text.trim()) ?? 0;
    final isCalculated = _nolonResult > 0;
    final usedRate = _customRate > 0 ? _customRate : (_governorateRates[_selectedGovernorate] ?? 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isCalculated
            ? LinearGradient(
                colors: [AppColors.success.withOpacity(0.08), AppColors.success.withOpacity(0.02)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              )
            : null,
        color: isCalculated ? null : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCalculated ? AppColors.success.withOpacity(0.2) : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isCalculated ? Icons.check_circle : Icons.calculate_outlined,
            size: 40,
            color: isCalculated ? AppColors.success : AppColors.textHint,
          ),
          const SizedBox(height: 12),
          Text(
            isCalculated ? 'قيمة النولون' : 'أدخل البيانات لحساب النولون',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isCalculated ? AppColors.textSecondary : AppColors.textHint,
            ),
          ),
          const SizedBox(height: 8),
          if (isCalculated) ...[
            Text(
              '$_nolonResult ج.م',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.success,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _ResultRow(
                    icon: Icons.location_on,
                    label: 'المحافظة',
                    value: _selectedGovernorate,
                  ),
                  const SizedBox(height: 6),
                  _ResultRow(
                    icon: Icons.scale,
                    label: 'الوزن',
                    value: '${weight.toStringAsFixed(0)} كم (${(weight / 1000).toStringAsFixed(1)} طن)',
                  ),
                  const SizedBox(height: 6),
                  _ResultRow(
                    icon: Icons.percent,
                    label: 'النسبة',
                    value: _customRate > 0
                        ? '${(usedRate * 100).toStringAsFixed(1)}% (يدوي)'
                        : '${(usedRate * 100).round()}%',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGovernorateReference() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.info),
              SizedBox(width: 6),
              Text('جدول نسب النولون حسب المحافظة (27 محافظة)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          ..._governorateGroups.map((group) {
            final govs = _getGovernoratesInGroup(group);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.info)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: govs.map((gov) {
                      final rate = _governorateRates[gov]!;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedGovernorate = gov;
                            _customRate = 0;
                          });
                          _calculateNolon();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _selectedGovernorate == gov
                                ? AppColors.primary.withOpacity(0.12)
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(6),
                            border: _selectedGovernorate == gov
                                ? Border.all(color: AppColors.primary.withOpacity(0.3))
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(gov, style: TextStyle(fontSize: 11, fontWeight: _selectedGovernorate == gov ? FontWeight.w700 : FontWeight.w500, color: _selectedGovernorate == gov ? AppColors.primary : AppColors.textSecondary)),
                              const SizedBox(width: 4),
                              Text('${(rate * 100).round()}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _getRateColor(rate))),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getRateColor(double rate) {
    if (rate >= 0.95) return AppColors.error;
    if (rate >= 0.85) return AppColors.accent;
    return AppColors.success;
  }

  // ═══════════════════════════════════════════════════════════════
  // CALCULATOR TAB
  // ═══════════════════════════════════════════════════════════════

  Widget _buildCalculatorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Display ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Expression
                Text(
                  _calcExpression.isEmpty ? '' : _calcExpression,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.5),
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Result
                Text(
                  _calcDisplay.text.isEmpty ? '0' : _calcDisplay.text,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                    height: 1.2,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Calculator Buttons ──
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                // Row 1: C, ⌫, %, ÷
                _buildCalcRow([
                  _CalcBtn(label: 'C', color: AppColors.error, textColor: Colors.white, onTap: () => _calcInput('C')),
                  _CalcBtn(label: '⌫', color: AppColors.surfaceVariant, textColor: AppColors.textPrimary, onTap: () => _calcInput('⌫')),
                  _CalcBtn(label: '%', color: AppColors.surfaceVariant, textColor: AppColors.primary, onTap: () => _calcInput('%')),
                  _CalcBtn(label: '÷', color: const Color(0xFF1565C0), textColor: Colors.white, onTap: () => _calcInput('÷')),
                ]),
                // Row 2: 7, 8, 9, ×
                _buildCalcRow([
                  _CalcBtn(label: '7', onTap: () => _calcInput('7')),
                  _CalcBtn(label: '8', onTap: () => _calcInput('8')),
                  _CalcBtn(label: '9', onTap: () => _calcInput('9')),
                  _CalcBtn(label: '×', color: const Color(0xFF1565C0), textColor: Colors.white, onTap: () => _calcInput('×')),
                ]),
                // Row 3: 4, 5, 6, -
                _buildCalcRow([
                  _CalcBtn(label: '4', onTap: () => _calcInput('4')),
                  _CalcBtn(label: '5', onTap: () => _calcInput('5')),
                  _CalcBtn(label: '6', onTap: () => _calcInput('6')),
                  _CalcBtn(label: '-', color: const Color(0xFF1565C0), textColor: Colors.white, onTap: () => _calcInput('-')),
                ]),
                // Row 4: 1, 2, 3, +
                _buildCalcRow([
                  _CalcBtn(label: '1', onTap: () => _calcInput('1')),
                  _CalcBtn(label: '2', onTap: () => _calcInput('2')),
                  _CalcBtn(label: '3', onTap: () => _calcInput('3')),
                  _CalcBtn(label: '+', color: const Color(0xFF1565C0), textColor: Colors.white, onTap: () => _calcInput('+')),
                ]),
                // Row 5: (, 0, ), =
                _buildCalcRow([
                  _CalcBtn(label: '(', color: AppColors.surfaceVariant, textColor: AppColors.textPrimary, onTap: () => _calcInput('(')),
                  _CalcBtn(label: '0', onTap: () => _calcInput('0')),
                  _CalcBtn(label: ')', color: AppColors.surfaceVariant, textColor: AppColors.textPrimary, onTap: () => _calcInput(')')),
                  _CalcBtn(label: '=', color: AppColors.success, textColor: Colors.white, onTap: () => _calcInput('=')),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Percentage shortcut buttons ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    const Text('اختصارات سريعة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _QuickCalcShortcut(label: '10%', expr: '*0.1', onTap: () { _calcExpression += '*0.1'; _calcInput('='); }),
                    _QuickCalcShortcut(label: '15%', expr: '*0.15', onTap: () { _calcExpression += '*0.15'; _calcInput('='); }),
                    _QuickCalcShortcut(label: '20%', expr: '*0.2', onTap: () { _calcExpression += '*0.2'; _calcInput('='); }),
                    _QuickCalcShortcut(label: '÷ 1000', expr: '/1000', onTap: () { _calcExpression += '/1000'; _calcInput('='); }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalcRow(List<_CalcBtn> buttons) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Row(
        children: buttons.map((btn) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: btn.onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: btn.color,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: btn.color == Colors.white
                          ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        btn.label,
                        style: TextStyle(
                          fontSize: btn.label.length > 2 ? 18 : 22,
                          fontWeight: FontWeight.w700,
                          color: btn.textColor ?? AppColors.textPrimary,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FUEL TAB
  // ═══════════════════════════════════════════════════════════════

  Widget _buildFuelTab() {
    return Column(
      children: [
        // Filter row
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _vehicleFilterLabel,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
              PopupMenuButton<int?>(
                key: const ValueKey('fuel_screen_menu'),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.filter_list_outlined, size: 18, color: AppColors.textSecondary),
                ),
                onSelected: (vehicleId) {
                  setState(() {
                    _selectedVehicleId = vehicleId;
                    final vehicles = context.read<VehicleProvider>().allVehicles;
                    if (vehicleId == null) {
                      _vehicleFilterLabel = 'جميع السيارات';
                    } else {
                      final v = vehicles.firstWhere(
                        (v) => v.id == vehicleId,
                        orElse: () => Vehicle(plateNumber: '', make: '', model: '', year: 2024, color: 'white', fuelType: 'petrol', currentOdometer: 0, status: 'active'),
                      );
                      _vehicleFilterLabel = v.plateNumber.isNotEmpty ? '${v.make} ${v.model}' : 'سيارة';
                    }
                  });
                  context.read<FuelProvider>().setVehicleFilter(vehicleId);
                },
                itemBuilder: (context) {
                  final vehicles = context.watch<VehicleProvider>().allVehicles;
                  return [
                    const PopupMenuItem<int?>(value: null, child: Row(children: [Icon(Icons.directions_car, size: 18), SizedBox(width: 8), Text('جميع السيارات')])),
                    if (vehicles.isNotEmpty) const PopupMenuDivider(),
                    ...vehicles.map((v) => PopupMenuItem<int?>(
                      value: v.id,
                      child: Row(children: [
                        Icon(Icons.directions_car, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('${v.make} ${v.model} - ${v.plateNumber}', overflow: TextOverflow.ellipsis)),
                      ]),
                    )),
                  ];
                },
              ),
            ],
          ),
        ),

        // Fuel records list
        Expanded(
          child: Consumer<FuelProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const LoadingWidget(message: 'جاري تحميل سجلات الوقود...');
              }

              if (provider.fuelRecords.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.local_gas_station_outlined,
                  title: 'لا توجد سجلات وقود',
                  subtitle: 'أضف سجل تعبئة وقود جديد',
                  actionText: 'إضافة سجل وقود',
                  onAction: () => Navigator.pushNamed(context, '/add-fuel'),
                );
              }

              return RefreshIndicator(
                onRefresh: () => provider.loadFuelRecords(),
                color: AppColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                  itemCount: provider.fuelRecords.length,
                  itemBuilder: (context, index) {
                    final record = provider.fuelRecords[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildFuelRecordCard(record, provider),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFuelRecordCard(FuelRecord record, FuelProvider provider) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: record.isAbnormal == true
            ? Border.all(color: AppColors.error.withOpacity(0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getFuelTypeColor(record.fuelType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getFuelTypeIcon(record.fuelType), color: _getFuelTypeColor(record.fuelType), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.vehicle?.plateNumber ?? 'سيارة #${record.vehicleId}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${record.vehicle?.make ?? ''} ${record.vehicle?.model ?? ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormatters.formatDate(record.fillDate),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  if (record.isAbnormal == true) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '⚠ استهلاك غير طبيعي',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.error),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildDetailItem(icon: Icons.water_drop, label: 'الكمية', value: '${record.liters.toStringAsFixed(1)} لتر'),
              const SizedBox(width: 20),
              _buildDetailItem(icon: Icons.monetization_on, label: 'التكلفة', value: AppFormatters.formatCurrency(record.totalCost)),
              const Spacer(),
              if (record.consumptionRate != null && record.consumptionRate! > 0)
                _buildDetailItem(
                  icon: Icons.speed,
                  label: 'الاستهلاك',
                  value: '${record.consumptionRate!.toStringAsFixed(1)} لتر/100كم',
                  valueColor: record.isAbnormal == true ? AppColors.error : null,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (record.fullTank)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('خزان كامل', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600)),
                ),
              if (record.stationName != null && record.stationName!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.ev_station, size: 12, color: AppColors.textHint),
                    const SizedBox(width: 3),
                    Text(record.stationName!, style: const TextStyle(fontSize: 10, color: AppColors.textHint), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ],
              const Spacer(),
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/add-fuel', arguments: record),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.edit_outlined, size: 18, color: AppColors.textHint),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => _confirmDelete(context, record.id!, provider),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline, size: 18, color: AppColors.textHint),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({required IconData icon, required String label, required String value, Color? valueColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
            Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.textPrimary),
            ),
          ],
        ),
      ],
    );
  }

  Color _getFuelTypeColor(String fuelType) {
    switch (fuelType) {
      case 'petrol': return AppColors.accent;
      case 'diesel': return AppColors.info;
      case 'electric': return AppColors.success;
      case 'hybrid': return AppColors.primary;
      case 'gas': return AppColors.warning;
      default: return AppColors.textSecondary;
    }
  }

  IconData _getFuelTypeIcon(String fuelType) {
    switch (fuelType) {
      case 'petrol': return Icons.local_gas_station;
      case 'diesel': return Icons.oil_barrel;
      case 'electric': return Icons.bolt;
      case 'hybrid': return Icons.electric_car;
      case 'gas': return Icons.propane_tank;
      default: return Icons.local_gas_station;
    }
  }

  void _confirmDelete(BuildContext context, int id, FuelProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف السجل'),
        content: const Text('هل أنت متأكد من حذف هذا السجل؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteFuelRecord(id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حذف السجل بنجاح'), behavior: SnackBarBehavior.floating),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Helper Widgets
// ═══════════════════════════════════════════════════════════════

class _QuickWeightBtn extends StatelessWidget {
  final String label;
  final double weight;
  final VoidCallback onTap;

  const _QuickWeightBtn({required this.label, required this.weight, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ResultRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }
}

class _CalcBtn {
  final String label;
  final Color color;
  final Color? textColor;
  final VoidCallback onTap;

  const _CalcBtn({
    required this.label,
    this.color = Colors.white,
    this.textColor,
    required this.onTap,
  });
}

class _QuickCalcShortcut extends StatelessWidget {
  final String label;
  final String expr;
  final VoidCallback onTap;

  const _QuickCalcShortcut({
    required this.label,
    required this.expr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
