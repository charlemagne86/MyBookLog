import 'package:flutter/material.dart';

/// BUSINESS LOGIC:
/// Users search for books by title and/or author.
/// Both fields are optional - user can search by just title, just author, or both.
/// Form collects user input and passes to parent via controller access.
///
/// TECHNICAL:
/// Stateless widget that provides two text fields with controllers.
/// Parent manages controller lifecycle.
/// Displays clear labels and hint text to guide user input.
class BookSearchForm extends StatelessWidget {
  const BookSearchForm({
    super.key,
    required this.titleController,
    required this.authorController,
  });

  final TextEditingController titleController;
  final TextEditingController authorController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header text
        const Text(
          'Search for a book...',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Title field
        TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Title',
            hintText: 'Enter book title',
          ),
        ),
        const SizedBox(height: 16),

        // Author field
        TextField(
          controller: authorController,
          decoration: const InputDecoration(
            labelText: 'Author',
            hintText: 'Enter author name',
          ),
        ),
      ],
    );
  }
}
