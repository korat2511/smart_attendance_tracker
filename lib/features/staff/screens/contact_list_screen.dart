import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/focus_utils.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../core/typography/app_typography.dart';
import '../../../core/widgets/loading_button.dart';
import 'manual_add_staff_screen.dart';
import 'add_staff_confirmation_dialog.dart';

class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Request contacts permission
      final granted = await FlutterContacts.requestPermission();
      
      if (!granted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Contacts permission is required to select staff members.';
        });
        return;
      }

      // Get contacts
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withThumbnail: false,
      );

      setState(() {
        _contacts = contacts;
        _filteredContacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load contacts: ${e.toString()}';
      });
    }
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _filteredContacts = _contacts;
      });
      return;
    }

    setState(() {
      _filteredContacts = _contacts.where((contact) {
        final name = contact.displayName.toLowerCase();
        final phones = contact.phones.map((p) => p.number.toLowerCase()).join(' ');
        return name.contains(query) || phones.contains(query);
      }).toList();
    });
  }

  String _getContactPhone(Contact contact) {
    if (contact.phones.isEmpty) {
      return 'No phone number';
    }
    // Get first phone number and clean it
    final phone = contact.phones.first.number;
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  Future<void> _handleContactSelected(Contact contact) async {
    FocusUtils.unfocus();
    
    final phone = _getContactPhone(contact);
    if (phone == 'No phone number') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected contact has no phone number'),
          backgroundColor: AppColors.warningRed,
        ),
      );
      return;
    }

    final name = contact.displayName.isNotEmpty ? contact.displayName : 'Unknown';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AddStaffConfirmationDialog(
        name: name,
        phoneNumber: phone,
      ),
    );

    if (confirmed == true) {
      // Navigate to manual form with pre-filled data
      if (!mounted) return;
      final result = await NavigationUtils.push(
        ManualAddStaffScreen(
          initialName: contact.displayName.isNotEmpty ? contact.displayName : '',
          initialPhone: phone,
        ),
      );

      if (result == true && mounted) {
        NavigationUtils.pop(true);
      }
    }
  }

  Future<void> _handleAddManual() async {
    FocusUtils.unfocus();
    final result = await NavigationUtils.push(
      const ManualAddStaffScreen(),
    );

    if (result == true && mounted) {
      NavigationUtils.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: FocusUtils.unfocus,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Select Contact'),
          elevation: 0,
        ),
        body: Column(
          children: [
            // Search bar
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
              color: theme.scaffoldBackgroundColor,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            // Add Manual button
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.horizontalPadding(context),
                vertical: 8,
              ),
              child: LoadingButton(
                text: 'Add Manual',
                onPressed: _handleAddManual,
                width: double.infinity,
              ),
            ),
            const Divider(height: 1),
            // Contacts list
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(
                              ResponsiveUtils.horizontalPadding(context),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: AppColors.warningRed,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  style: AppTypography.bodyLarge(
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                LoadingButton(
                                  text: 'Retry',
                                  onPressed: _loadContacts,
                                  width: 200,
                                ),
                              ],
                            ),
                          ),
                        )
                      : _filteredContacts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.contacts_outlined,
                                    size: 64,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchController.text.isEmpty
                                        ? 'No contacts found'
                                        : 'No contacts match your search',
                                    style: AppTypography.bodyLarge(
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredContacts.length,
                              itemBuilder: (context, index) {
                                final contact = _filteredContacts[index];
                                final phone = _getContactPhone(contact);
                                final name = contact.displayName.isNotEmpty ? contact.displayName : 'Unknown';

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: AppTypography.titleMedium(
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    name,
                                    style: AppTypography.bodyLarge(
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  subtitle: Text(
                                    phone,
                                    style: AppTypography.bodyMedium(
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () => _handleContactSelected(contact),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
