import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/layout/app_layout.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/add_members_provider.dart';
import '../services/group_service.dart';
import '../widgets/gradient_create_button.dart';
import '../widgets/member_user_card.dart';

class AddMembersScreen extends ConsumerStatefulWidget {
  const AddMembersScreen({
    required this.user,
    required this.groupId,
    required this.groupName,
    super.key,
  });

  final AppUser user;
  final String groupId;
  final String groupName;

  @override
  ConsumerState<AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends ConsumerState<AddMembersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(addMembersProvider.notifier)
          .initialize(widget.groupId, widget.user.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addMembersProvider);
    final notifier = ref.read(addMembersProvider.notifier);

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Members'),
              Text(
                widget.groupName,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: AppLayout.pagePadding(context),
                    child: TextField(
                      onChanged: notifier.setSearch,
                      decoration: const InputDecoration(
                        hintText: 'Search by name or email',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  if (state.selectedIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected (${state.selectedIds.length})',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: state.selectedUsers
                                  .map(
                                    (u) => Chip(
                                      label: Text(u.name),
                                      onDeleted: () => notifier.toggle(u),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: state.filteredUsers.isEmpty
                        ? Center(
                            child: Padding(
                              padding: AppLayout.pagePadding(context),
                              child: Text(
                                state.searchQuery.trim().isEmpty
                                    ? 'Everyone is already in this group.'
                                    : 'No users match your search.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: AppLayout.pagePadding(context),
                            itemCount: state.filteredUsers.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final user = state.filteredUsers[i];
                              return MemberUserCard(
                                user: user,
                                selected: state.selectedIds.contains(user.uid),
                                onTap: () => notifier.toggle(user),
                              );
                            },
                          ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: AppLayout.pagePadding(context),
                      child: GradientCreateButton(
                        label: 'Add Members',
                        isLoading: state.isSubmitting,
                        onPressed: state.isSubmitting ? null : _submit,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _submit() async {
    try {
      await ref
          .read(addMembersProvider.notifier)
          .submit(
            widget.user.uid,
            widget.user.fullName.isEmpty ? 'You' : widget.user.fullName,
          );
      if (!mounted) return;
      showAppSnackBar(context, 'Members added successfully!');
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
