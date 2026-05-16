import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/layout/app_layout.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/edit_group_provider.dart';
import '../services/group_service.dart';
import '../widgets/gradient_create_button.dart';

class EditGroupScreen extends ConsumerStatefulWidget {
  const EditGroupScreen({
    required this.user,
    required this.groupId,
    super.key,
  });

  final AppUser user;
  final String groupId;

  @override
  ConsumerState<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends ConsumerState<EditGroupScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editGroupProvider.notifier).load(widget.groupId);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editGroupProvider);
    final notifier = ref.read(editGroupProvider.notifier);

    if (!state.isLoading &&
        _nameController.text.isEmpty &&
        state.groupName.isNotEmpty) {
      _nameController.text = state.groupName;
      _descController.text = state.description;
    }

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('Edit Group'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: AppLayout.pagePadding(context).copyWith(
                  bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: AppLayout.contentMaxWidth(context),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: state.isSubmitting ? null : notifier.pickImage,
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.12),
                            backgroundImage: state.groupImagePath.isNotEmpty &&
                                    File(state.groupImagePath).existsSync()
                                ? FileImage(File(state.groupImagePath))
                                : null,
                            child: state.groupImagePath.isEmpty
                                ? Icon(
                                    Icons.camera_alt_outlined,
                                    color: AppColors.primaryColor(
                                      Theme.of(context).brightness,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _nameController,
                                enabled: !state.isSubmitting,
                                decoration: InputDecoration(
                                  labelText: 'Group name',
                                  errorText: state.nameError,
                                ),
                                onChanged: notifier.setGroupName,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _descController,
                                enabled: !state.isSubmitting,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Description',
                                ),
                                onChanged: notifier.setDescription,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    color: AppColors.primaryColor(
                                      Theme.of(context).brightness,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${state.memberCount} members',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        GradientCreateButton(
                          label: 'Save Changes',
                          isLoading: state.isSubmitting,
                          onPressed: state.isSubmitting ? null : _save,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _save() async {
    final notifier = ref.read(editGroupProvider.notifier);
    notifier.setGroupName(_nameController.text);
    notifier.setDescription(_descController.text);
    try {
      await notifier.save(widget.user.uid);
      if (!mounted) return;
      showAppSnackBar(context, 'Group updated successfully!');
      Navigator.pop(context, true);
    } on GroupServiceException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, groupServiceErrorMessage(e), isError: true);
    }
  }
}
