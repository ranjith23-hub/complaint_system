// job_details.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:complaint_system/models/complaint_model.dart';
import 'package:complaint_system/services/gamification_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:complaint_system/services/email_service.dart';
class JobDetailScreen extends StatefulWidget {
  final Complaint task;
  const JobDetailScreen({super.key, required this.task});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {

  static const primaryPurple = Color(0xFF5B2D91);

  final TextEditingController _resolutionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;

  late String _liveStage;

  // Normalize DB value
  String _normalize(String s) => s.trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    _liveStage = widget.task.status;
  }

  // ================= MAP =================
  Future<void> _openGoogleMaps() async {
    final Uri uri = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=${widget.task.latitude},${widget.task.longitude}"
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ================= UPDATE STATUS =================
  Future<void> _updateFirestoreTask(String newStatus, {String? resolution}) async {
    await FirebaseFirestore.instance
        .collection('complaints')
        .doc(widget.task.complaintId)
        .update({
      'status': newStatus,
      if (resolution != null) 'resolutionDetails': resolution,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      widget.task.status = newStatus;
      _liveStage = newStatus;
    });
  }

  // ================= DUMMY NOTIFICATION =================
  Future<void> _notifyCitizenAndStart() async {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📢 Citizen notified (dummy push notification)"))
    );

    await _updateFirestoreTask("In Progress");
  }

  // ================= PICK IMAGE =================
  Future<void> _pickImage() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img != null) setState(() => _pickedImage = File(img.path));
  }

  // ================= TIMELINE =================
  Widget _trackingTimeline() {

    final stages = [
      "Assigned",
      "On The Way",
      "In Progress",
      "Resolved"
    ];

    String normalized = _normalize(_liveStage);

    if (normalized == "pending" || normalized == "classified") {
      normalized = "assigned";
    }

    int currentIndex = stages.indexWhere(
            (s) => _normalize(s) == normalized
    );

    if (currentIndex == -1) currentIndex = 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18)
      ),
      child: Column(
        children: List.generate(stages.length, (index) {

          bool completed = index <= currentIndex;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: completed ? primaryPurple : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: completed
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  if (index != stages.length - 1)
                    Container(
                      width: 2,
                      height: 40,
                      color: completed ? primaryPurple : Colors.grey.shade300,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  stages[index],
                  style: TextStyle(
                    fontWeight: completed ? FontWeight.bold : FontWeight.normal,
                    color: completed ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ================= ACTION BUTTONS =================
  Widget _actionButtons() {

    String stage = _normalize(_liveStage);

    if (stage == "pending" || stage == "classified") stage = "assigned";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          if (stage == "assigned")
            _primaryButton(
                "NOTIFY CITIZEN & START WORK",
                Icons.notifications_active,
                _notifyCitizenAndStart
            ),

          if (stage == "in progress")
            _secondaryButton(
                "SUBMIT WORK & RESOLVE",
                Icons.check_circle,
                _showResolutionDialog
            ),
        ],
      ),
    );
  }

  // ================= RESOLUTION =================
  void _showResolutionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            const Text("Submit Work Proof",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

            const SizedBox(height: 16),

            TextField(
              controller: _resolutionController,
              decoration: const InputDecoration(
                  labelText: "Action Taken",
                  border: OutlineInputBorder()),
            ),

            const SizedBox(height: 16),

            InkWell(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey)
                ),
                child: _pickedImage != null
                    ? Image.file(_pickedImage!, fit: BoxFit.cover)
                    : const Center(child: Icon(Icons.camera_alt, size: 40)),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
                onPressed: () async {

                  // 1️⃣ Update status to Resolved
                  await _updateFirestoreTask(
                    "Resolved",
                    resolution: _resolutionController.text,
                  );

                  // 2️⃣ Award points
                  await GamificationService()
                      .awardPointsForResolution(widget.task.userId);

                  // 3️⃣ Get user email from Firestore
                  DocumentSnapshot userDoc = await FirebaseFirestore.instance
                      .collection('Users')
                      .doc(widget.task.userId)
                      .get();

                  String userEmail = userDoc['email'];
                  String userName = userDoc['name'];

                  // 4️⃣ Send email
                  final emailService = EmailService();

                  emailService.sendStatusEmail(
                    userEmail,
                    "Your Complaint Has Been Resolved ✅",
                    """
                          Hi $userName,
                          
                          Good news! 🎉
                          
                          Your complaint has been successfully resolved.
                          
                          Complaint ID: ${widget.task.complaintId}
                          Title: ${widget.task.title}
                          Status: Resolved
                          
                          Please open the CivicConnect app and provide your feedback.
                          
                          Thank you for being a responsible citizen!
                          
                          Regards,
                          CivicConnect Team
                          """,
                  );

                  // 5️⃣ Close screens
                  Navigator.pop(context);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("✅ Complaint resolved, points awarded & email sent"))
                  );
                },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50)),
              child: const Text("FINALIZE & CLOSE"),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Execution Details"),
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: _actionButtons(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16,16,16,120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _headerCard(),
            const SizedBox(height:20),
            _trackingTimeline(),
            const SizedBox(height:20),

            const Text("Issue Description",
                style: TextStyle(fontWeight: FontWeight.bold)),

            _card(Text(widget.task.description)),

            const SizedBox(height:20),

            const Text("Location",
                style: TextStyle(fontWeight: FontWeight.bold)),

            _card(Row(
              children: [
                const Icon(Icons.location_on,color: Colors.red),
                Expanded(child: Text("Lat: ${widget.task.latitude}, Lon: ${widget.task.longitude}")),
                ElevatedButton(onPressed: _openGoogleMaps, child: const Text("Navigate"))
              ],
            )),

            if(widget.task.imageUrl != null && widget.task.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top:20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(widget.task.imageUrl!),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _headerCard() => _card(Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(widget.task.title,
          style: const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
      const SizedBox(height:8),
      Row(children:[
        Chip(label:Text(widget.task.status)),
        const SizedBox(width:8),
        Chip(label:Text(widget.task.category))
      ])
    ],
  ));

  Widget _card(Widget child)=>Container(
    width:double.infinity,
    padding:const EdgeInsets.all(14),
    margin:const EdgeInsets.only(top:8),
    decoration:BoxDecoration(
        color:Colors.white,
        borderRadius:BorderRadius.circular(14)
    ),
    child:child,
  );

  Widget _primaryButton(String text, IconData icon, VoidCallback onTap)=>SizedBox(
    width:double.infinity,
    height:50,
    child:ElevatedButton.icon(onPressed:onTap,icon:Icon(icon),label:Text(text)),
  );

  Widget _secondaryButton(String text, IconData icon, VoidCallback onTap)=>SizedBox(
    width:double.infinity,
    height:50,
    child:OutlinedButton.icon(onPressed:onTap,icon:Icon(icon),label:Text(text)),
  );
}
