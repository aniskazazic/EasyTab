import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/review.dart';
import 'package:flutter/material.dart';

class AdminReviewsDetailsScreen extends StatefulWidget {
  final Review review;

  const AdminReviewsDetailsScreen({super.key, required this.review});

  @override
  State<AdminReviewsDetailsScreen> createState() =>
      _AdminReviewsDetailsScreenState();
}

class _AdminReviewsDetailsScreenState extends State<AdminReviewsDetailsScreen> {
  bool isLoading = false;

  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.review.description);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Admin Reviews Details',
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              SizedBox(height: 30),
              isLoading
                  ? CircularProgressIndicator()
                  : Text(
                      "Recezent: ${widget.review.userFullName ?? 'Korisnik'}",
                      style: TextStyle(fontSize: 20),
                    ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Icon(
                    index < (widget.review.rating ?? 0)
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 30,
                  );
                }),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: 600,
                child: TextField(
                  controller: _controller,
                  readOnly: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Review Description',
                  ),
                  maxLines: 5,
                  maxLength: 1000,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
