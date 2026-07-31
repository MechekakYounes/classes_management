import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_gp/core/services/api_service.dart';

class EditPaymentStatusDialog extends StatefulWidget {
  final Map<String, dynamic> student;

  const EditPaymentStatusDialog({
    Key? key,
    required this.student,
  }) : super(key: key);

  @override
  State<EditPaymentStatusDialog> createState() =>
      _EditPaymentStatusDialogState();
}

class _EditPaymentStatusDialogState
    extends State<EditPaymentStatusDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _hifdhController;

  bool _loading = false;

  int _paymentStatus = 0;

  @override
  void initState() {
    super.initState();

    _hifdhController = TextEditingController(
      text: widget.student['hifdh']?.toString() ?? '',
    );

    _paymentStatus = int.tryParse(
          widget.student['payement_status'].toString(),
        ) ??
        0;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await ApiService.updateStudent(
        widget.student['id'],
        {
          "hifdh": _hifdhController.text.trim(),
          "payement_status": _paymentStatus,
        },
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error : $e"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final studentName =
        "${widget.student['fname']} ${widget.student['name']}";

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(
          maxWidth: 450,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Text(
                "Payment & Hifdh",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan.shade800,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                studentName,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 25),

              TextFormField(
                controller: _hifdhController,
                decoration: InputDecoration(
                  labelText: "Hifdh",
                  prefixIcon: const Icon(
                    FontAwesomeIcons.bookQuran,
                    color: Colors.cyan,
                    size: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 18),

              DropdownButtonFormField<int>(
                value: _paymentStatus,
                decoration: InputDecoration(
                  labelText: "Payment Status",
                  prefixIcon: const Icon(
                    FontAwesomeIcons.moneyBill,
                    color: Colors.green,
                    size: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 1,
                    child: Text("Paid"),
                  ),
                  DropdownMenuItem(
                    value: 0,
                    child: Text("Unpaid"),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _paymentStatus = value!;
                  });
                },
              ),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),

                  const SizedBox(width: 10),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Save",
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}