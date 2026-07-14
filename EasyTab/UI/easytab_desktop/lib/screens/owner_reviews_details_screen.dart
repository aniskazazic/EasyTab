import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/review.dart';
import 'package:flutter/material.dart';

class OwnerReviewsDetailsScreen extends StatefulWidget {
  final Review review;

  const OwnerReviewsDetailsScreen({super.key, required this.review});

  @override
  State<OwnerReviewsDetailsScreen> createState() =>
      _OwnerReviewsDetailsScreenState();
}

class _OwnerReviewsDetailsScreenState extends State<OwnerReviewsDetailsScreen> {
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
      title: 'Detalji recenzije',
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              const SizedBox(height: 30),
              isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                      "Recezent: ${widget.review.userFullName ?? 'Korisnik'}",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 20),
              SizedBox(
                width: 600,
                child: TextField(
                  controller: _controller,
                  readOnly: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Opis recenzije',
                  ),
                  maxLines: 8,
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
