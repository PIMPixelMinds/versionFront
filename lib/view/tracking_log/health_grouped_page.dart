import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/utils/utils.dart';
import '../../data/repositories/historique_repository.dart';
import '../../core/constants/app_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HealthGroupedPage extends StatefulWidget {
  @override
  _HealthGroupedPageState createState() => _HealthGroupedPageState();
}

class _HealthGroupedPageState extends State<HealthGroupedPage> {
  List<dynamic> groupedHistorique = [];
  bool isLoading = true;
  int currentPage = 0;
  int itemsPerPage = 10;

  late final HistoryRepository _historyRepository;

  @override
  void initState() {
    super.initState();
    _historyRepository = HistoryRepository(GlobalKey()); // placeholder, not used for screenshot here
    fetchGroupedHistorique().then((_) => checkForPainNeedPopup());
  }

  String getTranslatedBodyPart(String key, AppLocalizations locale) {
  switch (key) {
    case 'head': return locale.head;
    case 'neck': return locale.neck;
    case 'leftShoulder': return locale.leftShoulder;
    case 'rightShoulder': return locale.rightShoulder;
    case 'leftUpperArm': return locale.leftUpperArm;
    case 'rightUpperArm': return locale.rightUpperArm;
    case 'leftElbow': return locale.leftElbow;
    case 'rightElbow': return locale.rightElbow;
    case 'leftLowerArm': return locale.leftLowerArm;
    case 'rightLowerArm': return locale.rightLowerArm;
    case 'leftHand': return locale.leftHand;
    case 'rightHand': return locale.rightHand;
    case 'upperBody': return locale.upperBody;
    case 'lowerBody': return locale.lowerBody;
    case 'abdomen': return locale.abdomen;
    case 'vestibular': return locale.vestibular;
    case 'leftUpperLeg': return locale.leftUpperLeg;
    case 'rightUpperLeg': return locale.rightUpperLeg;
    case 'leftKnee': return locale.leftKnee;
    case 'rightKnee': return locale.rightKnee;
    case 'leftLowerLeg': return locale.leftLowerLeg;
    case 'rightLowerLeg': return locale.rightLowerLeg;
    case 'leftFoot': return locale.leftFoot;
    case 'rightFoot': return locale.rightFoot;
    default: return key;
  }
}

  Future<void> checkForPainNeedPopup() async {
    try {
      final needsPainCheckRecords = await _historyRepository.getHistoriqueNeedsPainCheck();

      if (needsPainCheckRecords.isNotEmpty) {
        final record = needsPainCheckRecords.first;
        final String historiqueId = record['_id'];
        final String zone = record['bodyPartName'] ?? "cette zone";

        final result = await _showPainCheckDialog(historiqueId, zone);

        if (result != null) {
          await _historyRepository.sendPainStatusUpdate(historiqueId, result);
          await fetchGroupedHistorique();
        }
      }
    } catch (e) {
      print("❌ Erreur récupération des douleurs needing check : $e");
    }
  }

  Future<void> fetchGroupedHistorique() async {
    try {
      List<dynamic> data = await _historyRepository.getGroupedHistorique();
      setState(() {
        groupedHistorique = data;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Erreur : $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchHistoriqueByDate(DateTime startDate, [DateTime? endDate]) async {
    setState(() => isLoading = true);

    try {
      final data = await _historyRepository.getHistoriqueByDate(startDate, endDate);

      Map<String, List<dynamic>> grouped = {};

      for (var item in data) {
        if (item['createdAt'] != null) {
          final createdAt = DateTime.parse(item['createdAt']);
          String dateKey = DateFormat('yyyy-MM-dd').format(createdAt);
          grouped.putIfAbsent(dateKey, () => []).add(item);
        }
      }

     setState(() {
  groupedHistorique = grouped.entries
      .map((e) => {'date': e.key, 'records': e.value})
      .toList()
    ..sort((a, b) =>
        DateTime.parse(b['date'] as String).compareTo(DateTime.parse(a['date'] as String)));
  isLoading = false;
});
    } catch (e) {
      print("❌ Erreur lors du filtre par date : $e");
      setState(() => isLoading = false);
    }
  }

  Future<bool?> _showPainCheckDialog(String historiqueId, String zoneCsv) async {
  final locale = AppLocalizations.of(context)!;
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  final translatedZones = zoneCsv
      .split(', ')
      .map((z) => getTranslatedBodyPart(z, locale))
      .join(', ');

  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        locale.painFollowUp,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        locale.stillInPainQuestion(translatedZones),
        style: TextStyle(
          color: isDarkMode ? Colors.white70 : Colors.black87,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            locale.no,
            style: TextStyle(color: AppColors.primaryBlue),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            locale.yes,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  ).then((result) async {
    if (result != null) {
      await _historyRepository.sendPainStatusUpdate(historiqueId, result);
      await fetchGroupedHistorique();
    }
    return result;
  });
}

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final allRecords = groupedHistorique.expand((group) => group['records'] as List).toList();
    final totalPages = (allRecords.length / itemsPerPage).ceil();
    final currentPageRecords = allRecords.skip(currentPage * itemsPerPage).take(itemsPerPage).toList();

    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : groupedHistorique.isEmpty
              ? Center(child: Text("No pain records available.", style: TextStyle(fontSize: 16)))
              : Column(
                  children: [
                    _buildDateFilterButton(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: currentPageRecords.length,
                        itemBuilder: (context, index) =>
                            _buildPainCard(currentPageRecords[index], index + 1 + currentPage * itemsPerPage),
                      ),
                    ),
                    _buildPaginationControls(totalPages),
                  ],
                ),
    );
  }

  Widget _buildDateFilterButton() {
    final locale = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: InkWell(
        onTap: _showDateFilterModal,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(locale.date, style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(width: 8),
              Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: currentPage > 0 ? () => setState(() => currentPage--) : null,
            icon: Icon(Icons.chevron_left),
          ),
          SizedBox(width: 16),
          Text("${currentPage + 1} / $totalPages"),
          SizedBox(width: 16),
          IconButton(
            onPressed: currentPage < totalPages - 1 ? () => setState(() => currentPage++) : null,
            icon: Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildPainCard(dynamic record, int index) {
  final bool isActive = record['isActive'] == true;
  final String? startTime = record['startTime'];
  final String? endTime = record['endTime'];
  final localeCode = Localizations.localeOf(context).languageCode;
  final local = AppLocalizations.of(context)!;

  final descriptionMap = record['generatedDescription'];
  final description = (descriptionMap is Map && descriptionMap.containsKey(localeCode))
      ? descriptionMap[localeCode]
      : (descriptionMap is String)
          ? descriptionMap
          : descriptionMap['en'] ?? 'No description';

  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
      color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecordImage(record['imageUrl']),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(
                      DateFormat('dd MMMM yyyy - HH:mm', localeCode)
                          .format(DateTime.parse(record['createdAt']).toLocal()),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                if (!isActive && endTime != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.stop_circle, size: 16, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text(
                          "${local.end} : ${DateFormat('dd MMMM yyyy - HH:mm', localeCode).format(DateTime.parse(endTime).toLocal())}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                if (startTime != null && isActive && record['wasOver24h'] != true)
                  StreamBuilder<Duration>(
                    stream: _liveDurationStream(DateTime.parse(startTime).toLocal()),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final d = snapshot.data!;
                      final h = d.inHours.toString().padLeft(2, '0');
                      final m = (d.inMinutes % 60).toString().padLeft(2, '0');
                      final s = (d.inSeconds % 60).toString().padLeft(2, '0');

                      return Row(
                        children: [
                          const Icon(Icons.timer, size: 16, color: Colors.grey),
                          const SizedBox(width: 5),
                          Text(
                            "$h:$m:$s",
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryBlue,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                if (record['wasOver24h'] == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              local.painOver24h,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildRecordImage(String imagePath) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        child: Image.network(
          "http://172.205.131.226:3000$imagePath",
          width: 250,
          height: 250,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 250,
            height: 250,
            color: Colors.grey.shade300,
            child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: 250,
              height: 250,
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }
  void _showDateFilterModal() {
    final locale = AppLocalizations.of(context)!;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // ✅ important pour responsive + clavier
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      String selected = 'Today';
      final options = {
  locale.today: 'Today',
  locale.thisWeek: 'This week',
  locale.thisMonth: 'This month',
  locale.thisQuarter: 'This quarter',
  locale.thisYear: 'This year',
  locale.custom: 'Custom'
};

      return StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6, // hauteur initiale (60%)
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (_, scrollController) => Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Date",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    ...options.entries.map((entry) {
  return RadioListTile(
    value: entry.value,
    groupValue: selected,
    activeColor: AppColors.primaryBlue,
    onChanged: (value) {
      setModalState(() => selected = value as String);
    },
    title: Text(entry.key),
  );
}).toList(),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context); // fermer le modal
                        DateTime now = DateTime.now();
                        DateTime start, end;

                        switch (selected) {
                          case 'Today':
                            await fetchHistoriqueByDate(now);
                            break;
                          case 'This week':
                            start = now.subtract(Duration(days: now.weekday - 1));
                            end = start.add(Duration(days: 6));
                            await fetchHistoriqueByDate(start, end);
                            break;
                          case 'This month':
                            start = DateTime(now.year, now.month, 1);
                            end = DateTime(now.year, now.month + 1, 0);
                            await fetchHistoriqueByDate(start, end);
                            break;
                          case 'This quarter':
                            int currentQuarter = ((now.month - 1) ~/ 3) + 1;
                            start = DateTime(now.year, (currentQuarter - 1) * 3 + 1, 1);
                            end = DateTime(now.year, currentQuarter * 3 + 1, 0);
                            await fetchHistoriqueByDate(start, end);
                            break;
                          case 'This year':
                            start = DateTime(now.year, 1, 1);
                            end = DateTime(now.year, 12, 31);
                            await fetchHistoriqueByDate(start, end);
                            break;
                          case 'Custom':
                            DateTimeRange? picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2023),
                              lastDate: now,
                              builder: (context, child) {
                                final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: isDarkMode
                                        ? ColorScheme.dark(
                                            primary: AppColors.primaryBlue,
                                            onPrimary: Colors.white,
                                            surface: Colors.grey[900]!,
                                            onSurface: Colors.white,
                                          )
                                        : ColorScheme.light(
                                            primary: AppColors.primaryBlue,
                                            onPrimary: Colors.white,
                                            onSurface: Colors.black,
                                          ),
                                    textButtonTheme: TextButtonThemeData(
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.primaryBlue,
                                      ),
                                    ),
                                    datePickerTheme: DatePickerThemeData(
                                      rangeSelectionBackgroundColor: AppColors.primaryBlue.withOpacity(0.3),
                                      rangePickerSurfaceTintColor: Colors.transparent,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              await fetchHistoriqueByDate(picked.start, picked.end);
                            }
                            break;
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(locale.apply, style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
Stream<Duration> _liveDurationStream(DateTime startTime) async* {
  while (true) {
    await Future.delayed(Duration(seconds: 1));
    yield DateTime.now().difference(startTime);
  }
}
}
