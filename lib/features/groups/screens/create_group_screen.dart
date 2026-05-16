import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/app_user.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../dashboard/widgets/animated_fade_slide.dart';
import '../providers/create_group_provider.dart';
import '../providers/groups_providers.dart';
import '../services/group_service.dart';
import '../widgets/gradient_create_button.dart';
import '../widgets/group_image_picker.dart';
import '../widgets/group_type_chips.dart';
import '../widgets/members_section.dart';
import '../widgets/premium_section_header.dart';
import '../widgets/section_card.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({required this.creator, super.key});

  final AppUser creator;

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(createGroupProvider.notifier).initialize(widget.creator);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final notifier = ref.read(createGroupProvider.notifier);
    notifier
      ..setGroupName(_nameController.text)
      ..setDescription(_descriptionController.text);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final users = await ref.read(appUsersProvider(widget.creator.uid).future);

    try {
      await notifier.submit(users);
      if (!mounted) return;
      showAppSnackBar(context, 'Group created successfully!');
      Navigator.of(context).pop(true);
    } on GroupServiceException catch (error) {
      if (!mounted) return;
      showAppSnackBar(context, error.message, isError: true);
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        groupServiceErrorMessage(error),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createGroupProvider);
    final notifier = ref.read(createGroupProvider.notifier);
    final brightness = Theme.of(context).brightness;

    if (!state.isInitialized) {
      return PremiumBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _buildAppBar(context),
          body: const Center(
            child: CircularProgressIndicator(color: AppColors.blue),
          ),
        ),
      );
    }

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        appBar: _buildAppBar(context),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewInsets = MediaQuery.viewInsetsOf(context);
              final hPad = constraints.maxWidth >= 600 ? 24.0 : 16.0;
              final maxWidth =
                  constraints.maxWidth >= 800 ? 640.0 : double.infinity;

              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(
                    hPad,
                    12,
                    hPad,
                    32 + viewInsets.bottom,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AnimatedFadeSlide(
                            child: SectionCard(
                              tint: AppColors.glassFill(brightness),
                              child: const Center(child: GroupImagePicker()),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimatedFadeSlide(
                            delay: const Duration(milliseconds: 60),
                            child: SectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  PremiumSectionHeader(
                                    title: 'Group Info',
                                    subtitle: 'Give your group a memorable name',
                                    accent: AppColors.blue,
                                  ),
                                  const SizedBox(height: 18),
                                  TextFormField(
                                    controller: _nameController,
                                    enabled: !state.isSubmitting,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    onChanged: notifier.setGroupName,
                                    decoration: InputDecoration(
                                      labelText: 'Group name',
                                      hintText: 'Enter group name',
                                      errorText: state.nameError,
                                      prefixIcon: Icon(
                                        Icons.label_outline_rounded,
                                        color: AppColors.blue.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                    ),
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                            ? 'Group name is required'
                                            : null,
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _descriptionController,
                                    enabled: !state.isSubmitting,
                                    maxLines: 3,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    onChanged: notifier.setDescription,
                                    decoration: InputDecoration(
                                      labelText: 'Description (optional)',
                                      hintText:
                                          'Trip, Flat expenses, Friends group...',
                                      alignLabelWithHint: true,
                                      prefixIcon: Icon(
                                        Icons.notes_rounded,
                                        color: AppColors.purple.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimatedFadeSlide(
                            delay: const Duration(milliseconds: 120),
                            child: SectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  PremiumSectionHeader(
                                    title: 'Group Type',
                                    accent: AppColors.purple,
                                  ),
                                  const SizedBox(height: 14),
                                  const GroupTypeChips(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimatedFadeSlide(
                            delay: const Duration(milliseconds: 180),
                            child: SectionCard(
                              child: MembersSection(
                                currentUserId: widget.creator.uid,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          AnimatedFadeSlide(
                            delay: const Duration(milliseconds: 240),
                            child: GradientCreateButton(
                              label: 'Create Group',
                              isLoading: state.isSubmitting,
                              onPressed: state.isSubmitting ? null : _submit,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'All amounts are tracked in ${AppColors.currencySymbol} (INR)',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.blue.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text('Create Group'),
    );
  }
}
