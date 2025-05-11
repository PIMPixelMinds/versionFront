// ✅ FINAL VERSION: Fully Integrated BodyPage with Enhanced HistoryRepository

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:body_part_selector/body_part_selector.dart';
import 'package:flutter/rendering.dart';
import 'package:pim/data/repositories/shared_prefs_service.dart';
import 'package:pim/data/repositories/historique_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;
import 'package:pim/view/body/firebase_historique_api.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class BodyPage extends StatefulWidget {
  @override
  _BodyPageState createState() => _BodyPageState();
}

class _BodyPageState extends State<BodyPage>
    with SingleTickerProviderStateMixin {
  final SharedPrefsService _prefsService = SharedPrefsService();
  final GlobalKey _globalKey = GlobalKey();
  late HistoryRepository _historyRepository;

  BodyParts _selectedParts = const BodyParts();
  bool isFrontView = true;
  TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  String? _token;

  late AnimationController _animationController;
  late Animation<double> _flipAnimation;

  String getTranslatedBodyPart(String key, AppLocalizations locale) {
  switch (key) {
    case 'head':
      return locale.head;
    case 'neck':
      return locale.neck;
    case 'leftShoulder':
      return locale.leftShoulder;
    case 'rightShoulder':
      return locale.rightShoulder;
    case 'leftUpperArm':
      return locale.leftUpperArm;
    case 'rightUpperArm':
      return locale.rightUpperArm;
    case 'leftElbow':
      return locale.leftElbow;
    case 'rightElbow':
      return locale.rightElbow;
    case 'leftLowerArm':
      return locale.leftLowerArm;
    case 'rightLowerArm':
      return locale.rightLowerArm;
    case 'leftHand':
      return locale.leftHand;
    case 'rightHand':
      return locale.rightHand;
    case 'upperBody':
      return locale.upperBody;
    case 'lowerBody':
      return locale.lowerBody;
    case 'leftUpperLeg':
      return locale.leftUpperLeg;
    case 'rightUpperLeg':
      return locale.rightUpperLeg;
    case 'leftKnee':
      return locale.leftKnee;
    case 'rightKnee':
      return locale.rightKnee;
    case 'leftLowerLeg':
      return locale.leftLowerLeg;
    case 'rightLowerLeg':
      return locale.rightLowerLeg;
    case 'leftFoot':
      return locale.leftFoot;
    case 'rightFoot':
      return locale.rightFoot;
    case 'abdomen':
      return locale.abdomen;
    case 'vestibular':
      return locale.vestibular;
    default:
      return key;
  }
}

bool _hasSelectedParts(BodyParts parts) {
  return [
    parts.head,
    parts.neck,
    parts.leftShoulder,
    parts.rightShoulder,
    parts.leftUpperArm,
    parts.rightUpperArm,
    parts.leftElbow,
    parts.rightElbow,
    parts.leftLowerArm,
    parts.rightLowerArm,
    parts.leftHand,
    parts.rightHand,
    parts.upperBody,
    parts.lowerBody,
    parts.leftUpperLeg,
    parts.rightUpperLeg,
    parts.leftKnee,
    parts.rightKnee,
    parts.leftLowerLeg,
    parts.rightLowerLeg,
    parts.leftFoot,
    parts.rightFoot,
    parts.abdomen,
    parts.vestibular,
  ].any((selected) => selected);
}
  final Map<String, int> bodyPartIndexMap = {
    'head': 1,
    'neck': 2,
    'leftShoulder': 3,
    'rightShoulder': 4,
    'leftUpperArm': 5,
    'rightUpperArm': 6,
    'leftElbow': 7,
    'rightElbow': 8,
    'leftLowerArm': 9,
    'rightLowerArm': 10,
    'leftHand': 11,
    'rightHand': 12,
    'upperBody': 13,
    'lowerBody': 14,
    'leftUpperLeg': 15,
    'rightUpperLeg': 16,
    'leftKnee': 17,
    'rightKnee': 18,
    'leftLowerLeg': 19,
    'rightLowerLeg': 20,
    'leftFoot': 21,
    'rightFoot': 22,
    'abdomen': 23,
    'vestibular': 24,
  };

  @override
  void initState() {
    super.initState();
    _loadToken();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _historyRepository = HistoryRepository(_globalKey);
  }

  Future<void> _loadToken() async {
    final token = await _prefsService.getAccessToken();
    setState(() {
      _token = token;
    });
    print("✅ JWT Token loaded: $_token");
  }

  void _onBodyPartSelected(BodyParts parts) {
    setState(() {
      _selectedParts = parts;
    });
    print("🧠 Selected part names: ${_getSelectedPartNames(parts)}");
  }

  List<String> _getSelectedPartNames(BodyParts parts) {
    final map = {
      'head': parts.head,
      'neck': parts.neck,
      'leftShoulder': parts.leftShoulder,
      'leftUpperArm': parts.leftUpperArm,
      'leftElbow': parts.leftElbow,
      'leftLowerArm': parts.leftLowerArm,
      'leftHand': parts.leftHand,
      'rightShoulder': parts.rightShoulder,
      'rightUpperArm': parts.rightUpperArm,
      'rightElbow': parts.rightElbow,
      'rightLowerArm': parts.rightLowerArm,
      'rightHand': parts.rightHand,
      'upperBody': parts.upperBody,
      'lowerBody': parts.lowerBody,
      'leftUpperLeg': parts.leftUpperLeg,
      'leftKnee': parts.leftKnee,
      'leftLowerLeg': parts.leftLowerLeg,
      'leftFoot': parts.leftFoot,
      'rightUpperLeg': parts.rightUpperLeg,
      'rightKnee': parts.rightKnee,
      'rightLowerLeg': parts.rightLowerLeg,
      'rightFoot': parts.rightFoot,
      'abdomen': parts.abdomen,
      'vestibular': parts.vestibular,
    };
    return map.entries.where((e) => e.value).map((e) => e.key).toList();
  }

  Future<void> _captureAndUploadScreenshot() async {
    if (_descriptionController.text.isEmpty) {
      _showErrorDialog("Please describe your pain.");
      return;
    }

    if (_token == null || _token!.isEmpty) {
      _showErrorDialog("You must be logged in.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception("Failed to encode image");

      Uint8List pngBytes = byteData.buffer.asUint8List();
      final file =
          File('${(await getTemporaryDirectory()).path}/screenshot.png');
      await file.writeAsBytes(pngBytes);

      final selectedNames = _getSelectedPartNames(_selectedParts);
      final selectedIndexes =
          selectedNames.map((name) => bodyPartIndexMap[name] ?? 0).toList();

      final fcmToken = await FirebaseHistoriqueApi().getFcmToken();

      final request = http.MultipartRequest(
          'POST', Uri.parse(ApiConstants.saveHistoriqueEndpoint))
        ..headers['Authorization'] = 'Bearer $_token'
        ..fields['userText'] = _descriptionController.text
        ..fields['bodyPartName'] = selectedNames.join(', ')
        ..fields['bodyPartIndex'] = selectedIndexes.join(', ')
        ..fields['fcmToken'] = fcmToken ?? ''
        ..files.add(await http.MultipartFile.fromPath(
          'screenshot',
          file.path,
          contentType: MediaType('image', 'png'),
        ));

      final response = await request.send();
      final responseString = await response.stream.bytesToString();
      print("🔍 Server response: $responseString");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showSuccessDialog();
      } else {
        print("❌ HTTP Error ${response.statusCode} : $responseString");
        throw Exception("Server rejected the upload.");
      }
    } catch (e) {
      _showErrorDialog("An error occurred. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDescriptionSheet() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final locale = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize
                    .min, // 👈 important pour ajuster avec le clavier
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                   locale.describePain,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: locale.painHint,
                      filled: true,
                      fillColor:
                          isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide
                            .none, // ✅ important : pas de ligne visible
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _captureAndUploadScreenshot();
                      },
                      label: Text(locale.send,
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

void _showSuccessDialog() {
  final locale = AppLocalizations.of(context)!;
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        locale.success,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        locale.successUpload,
        style: TextStyle(
          color: isDarkMode ? Colors.white70 : Colors.black87,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text("OK", style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

  void _showErrorDialog(String message) {
  final locale = AppLocalizations.of(context)!;
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      title: Text(
        locale.error,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      content: Text(
        message,
        style: TextStyle(
          color: isDarkMode ? Colors.white70 : Colors.black87,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryBlue, // ✅ Couleur du texte
          ),
          child: Text("OK"),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
  title: Text(locale.bodySelection,
  style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              
            )),
  centerTitle: true,
  backgroundColor: Theme.of(context).brightness == Brightness.dark
      ? Colors.black
      : Colors.white, // null utilise la couleur par défaut en mode clair
        actions: [
  Padding(
    padding: const EdgeInsets.only(right: 12),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              isFrontView = !isFrontView;
              isFrontView
                  ? _animationController.reverse()
                  : _animationController.forward();
            });
          },
          child: Icon(
            Icons.cached,
            size: 24, // ⚠️ réduis un peu pour éviter l’overflow
            color: AppColors.primaryBlue,
          ),
        ),
        SizedBox(height: 4),
        Text(
          isFrontView ? locale.front : locale.back,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: RepaintBoundary(
              key: _globalKey,
              child: BodyPartSelector(
                bodyParts: _selectedParts,
                onSelectionUpdated: _onBodyPartSelected,
                side: isFrontView ? BodySide.front : BodySide.back,
                selectedColor: AppColors.primaryBlue,
                selectedOutlineColor: AppColors.primaryBlue,
              ),
            ),
          ),
          Expanded(
  flex: 1,
  child: Center(
    child: _hasSelectedParts(_selectedParts)
  ? Text(
      locale.selectedZone(_getSelectedPartNames(_selectedParts)
    .map((e) => getTranslatedBodyPart(e, locale))
    .join(', ')),
      textAlign: TextAlign.center,
      style: const TextStyle(fontWeight: FontWeight.w500),
    )
  : Text(
      locale.noZone,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.grey),
    )
  ),
)
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: _showDescriptionSheet,
          icon: const Icon(Icons.edit, color: Colors.white),
          label: Text(locale.describe, style: const TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            minimumSize: const Size.fromHeight(50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
