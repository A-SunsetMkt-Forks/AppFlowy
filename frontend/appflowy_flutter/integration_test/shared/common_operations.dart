import 'dart:io';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/type_option_menu_item.dart';
import 'package:appflowy/mobile/presentation/presentation.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/emoji_picker_button.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/add_block_toolbar_item.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_widgets/_simple_table_bottom_sheet_actions.dart';
import 'package:appflowy/plugins/shared/share/share_button.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/shared/text_field/text_filed_with_metric_lines.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/presentation/screens/screens.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/widgets.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/favorites/favorite_folder.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/footer/sidebar_footer.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/shared/sidebar_new_page_button.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/sidebar_space_header.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/sidebar_space_menu.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon_popup.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_menu.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/sidebar_workspace.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/draggable_view_item.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_action_type.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_add_button.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_more_action_button.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/flowy_tab.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notification_button.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notification_tab_bar.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_menu.dart';
import 'package:appflowy/workspace/presentation/widgets/dialog_v2.dart';
import 'package:appflowy/workspace/presentation/widgets/more_view_actions/more_view_actions.dart';
import 'package:appflowy/workspace/presentation/widgets/more_view_actions/widgets/common_view_action.dart';
import 'package:appflowy/workspace/presentation/widgets/view_title_bar.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/buttons/primary_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:universal_platform/universal_platform.dart';

import 'emoji.dart';
import 'util.dart';

extension CommonOperations on WidgetTester {
  /// Tap the GetStart button on the launch page.
  Future<void> tapAnonymousSignInButton() async {
    // local version
    final goButton = find.byType(GoButton);
    if (goButton.evaluate().isNotEmpty) {
      await tapButton(goButton);
    } else {
      // cloud version
      final anonymousButton = find.byType(SignInAnonymousButtonV2);
      await tapButton(anonymousButton, warnIfMissed: true);
    }

    await pumpAndSettle(const Duration(milliseconds: 200));
  }

  Future<void> tapContinousAnotherWay() async {
    // local version
    await tapButtonWithName(LocaleKeys.signIn_continueAnotherWay.tr());
    if (Platform.isWindows) {
      await pumpAndSettle(const Duration(milliseconds: 200));
    }
  }

  /// Tap the + button on the home page.
  Future<void> tapAddViewButton({
    String name = gettingStarted,
    ViewLayoutPB layout = ViewLayoutPB.Document,
  }) async {
    await hoverOnPageName(
      name,
      onHover: () async {
        final addButton = find.byType(ViewAddButton);
        await tapButton(addButton);
      },
    );
  }

  /// Tap the 'New Page' Button on the sidebar.
  Future<void> tapNewPageButton() async {
    final newPageButton = find.byType(SidebarNewPageButton);
    await tapButton(newPageButton);
  }

  /// Tap the import button.
  ///
  /// Must call [tapAddViewButton] first.
  Future<void> tapImportButton() async {
    await tapButtonWithName(LocaleKeys.moreAction_import.tr());
  }

  /// Tap the import from text & markdown button.
  ///
  /// Must call [tapImportButton] first.
  Future<void> tapTextAndMarkdownButton() async {
    await tapButtonWithName(LocaleKeys.importPanel_textAndMarkdown.tr());
  }

  /// Tap the LanguageSelectorOnWelcomePage widget on the launch page.
  Future<void> tapLanguageSelectorOnWelcomePage() async {
    final languageSelector = find.byType(LanguageSelectorOnWelcomePage);
    await tapButton(languageSelector);
  }

  /// Tap languageItem on LanguageItemsListView.
  ///
  /// [scrollDelta] is the distance to scroll the ListView.
  /// Default value is 100
  ///
  /// If it is positive -> scroll down.
  ///
  /// If it is negative -> scroll up.
  Future<void> tapLanguageItem({
    required String languageCode,
    String? countryCode,
    double? scrollDelta,
  }) async {
    final languageItemsListView = find.descendant(
      of: find.byType(ListView),
      matching: find.byType(Scrollable),
    );

    final languageItem = find.byWidgetPredicate(
      (widget) =>
          widget is LanguageItem &&
          widget.locale.languageCode == languageCode &&
          widget.locale.countryCode == countryCode,
    );

    // scroll the ListView until zHCNLanguageItem shows on the screen.
    await scrollUntilVisible(
      languageItem,
      scrollDelta ?? 100,
      scrollable: languageItemsListView,
      // maxHeight of LanguageItemsListView
      maxScrolls: 400,
    );

    try {
      await tapButton(languageItem);
    } on FlutterError catch (e) {
      Log.warn('tapLanguageItem error: $e');
    }
  }

  /// Hover on the widget.
  Future<void> hoverOnWidget(
    Finder finder, {
    Offset? offset,
    Future<void> Function()? onHover,
    bool removePointer = true,
  }) async {
    try {
      final gesture = await createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: offset ?? getCenter(finder));
      await pumpAndSettle();
      await onHover?.call();
      await gesture.removePointer();
    } catch (err) {
      Log.error('hoverOnWidget error: $err');
    }
  }

  /// Hover on the page name.
  Future<void> hoverOnPageName(
    String name, {
    ViewLayoutPB layout = ViewLayoutPB.Document,
    Future<void> Function()? onHover,
    bool useLast = true,
  }) async {
    final pageNames = findPageName(name, layout: layout);
    if (useLast) {
      await hoverOnWidget(pageNames.last, onHover: onHover);
    } else {
      await hoverOnWidget(pageNames.first, onHover: onHover);
    }
  }

  /// Right click on the page name.
  Future<void> rightClickOnPageName(
    String name, {
    ViewLayoutPB layout = ViewLayoutPB.Document,
  }) async {
    final page = findPageName(name, layout: layout);
    await hoverOnPageName(
      name,
      onHover: () async {
        await tap(page, buttons: kSecondaryMouseButton);
        await pumpAndSettle();
      },
    );
  }

  /// open the page with given name.
  Future<void> openPage(
    String name, {
    ViewLayoutPB layout = ViewLayoutPB.Document,
  }) async {
    final finder = findPageName(name, layout: layout);
    expect(finder, findsOneWidget);
    await tapButton(finder);
  }

  /// Tap the ... button beside the page name.
  ///
  /// Must call [hoverOnPageName] first.
  Future<void> tapPageOptionButton() async {
    final optionButton = find.descendant(
      of: find.byType(ViewMoreActionPopover),
      matching: find.byFlowySvg(FlowySvgs.workspace_three_dots_s),
    );
    await tapButton(optionButton);
  }

  /// Tap the delete page button.
  Future<void> tapDeletePageButton() async {
    await tapPageOptionButton();
    await tapButtonWithName(ViewMoreActionType.delete.name);
  }

  /// Tap the rename page button.
  Future<void> tapRenamePageButton() async {
    await tapPageOptionButton();
    await tapButtonWithName(ViewMoreActionType.rename.name);
  }

  /// Tap the favorite page button
  Future<void> tapFavoritePageButton() async {
    await tapPageOptionButton();
    await tapButtonWithName(ViewMoreActionType.favorite.name);
  }

  /// Tap the unfavorite page button
  Future<void> tapUnfavoritePageButton() async {
    await tapPageOptionButton();
    await tapButtonWithName(ViewMoreActionType.unFavorite.name);
  }

  /// Tap the Open in a new tab button
  Future<void> tapOpenInTabButton() async {
    await tapPageOptionButton();
    await tapButtonWithName(ViewMoreActionType.openInNewTab.name);
  }

  /// Rename the page.
  Future<void> renamePage(String name) async {
    await tapRenamePageButton();
    await enterText(find.byType(AFTextField), name);
    await tapButton(find.text(LocaleKeys.button_confirm.tr()));
  }

  Future<void> tapTrashButton() async {
    await tap(find.byType(SidebarTrashButton));
  }

  Future<void> tapOKButton() async {
    final okButton = find.byWidgetPredicate(
      (widget) =>
          widget is PrimaryTextButton &&
          widget.label == LocaleKeys.button_ok.tr(),
    );
    await tapButton(okButton);
  }

  /// Expand or collapse the page.
  Future<void> expandOrCollapsePage({
    required String pageName,
    required ViewLayoutPB layout,
  }) async {
    final page = findPageName(pageName, layout: layout);
    await hoverOnWidget(page);
    final expandButton = find.descendant(
      of: page,
      matching: find.byType(ViewItemDefaultLeftIcon),
    );
    await tapButton(expandButton.first);
  }

  /// Tap the restore button.
  ///
  /// the restore button will show after the current page is deleted.
  Future<void> tapRestoreButton() async {
    final restoreButton = find.textContaining(
      LocaleKeys.deletePagePrompt_restore.tr(),
    );
    await tapButton(restoreButton);
  }

  /// Tap the delete permanently button.
  ///
  /// the delete permanently button will show after the current page is deleted.
  Future<void> tapDeletePermanentlyButton() async {
    final deleteButton = find.textContaining(
      LocaleKeys.deletePagePrompt_deletePermanent.tr(),
    );
    await tapButton(deleteButton);
    await tap(find.text(LocaleKeys.button_delete.tr()));
    await pumpAndSettle();
  }

  /// Tap the share button above the document page.
  Future<void> tapShareButton() async {
    final shareButton = find.byWidgetPredicate(
      (widget) => widget is ShareButton,
    );
    await tapButton(shareButton);
  }

  // open the share menu and then click the publish tab
  Future<void> openPublishMenu() async {
    await tapShareButton();
    final publishButton = find.textContaining(
      LocaleKeys.shareAction_publishTab.tr(),
    );
    await tapButton(publishButton);
  }

  /// Tap the export markdown button
  ///
  /// Must call [tapShareButton] first.
  Future<void> tapMarkdownButton() async {
    final markdownButton = find.textContaining(
      LocaleKeys.shareAction_markdown.tr(),
    );
    await tapButton(markdownButton);
  }

  Future<void> createNewPageWithNameUnderParent({
    String? name,
    ViewLayoutPB layout = ViewLayoutPB.Document,
    String? parentName,
    bool openAfterCreated = true,
  }) async {
    // create a new page
    await tapAddViewButton(name: parentName ?? gettingStarted, layout: layout);
    await tapButtonWithName(layout.menuName);
    final settingsOrFailure = await getIt<KeyValueStorage>().getWithFormat(
      KVKeys.showRenameDialogWhenCreatingNewFile,
      (value) => bool.parse(value),
    );
    final showRenameDialog = settingsOrFailure ?? false;
    if (showRenameDialog) {
      await tapButton(find.text(LocaleKeys.button_confirm.tr()));
    }
    await pumpAndSettle();

    // hover on it and change it's name
    if (name != null) {
      await hoverOnPageName(
        layout.defaultName,
        layout: layout,
        onHover: () async {
          await renamePage(name);
          await pumpAndSettle();
        },
      );
      await pumpAndSettle();
    }

    // open the page after created
    if (openAfterCreated) {
      await openPage(
        // if the name is null, use the default name
        name ?? layout.defaultName,
        layout: layout,
      );
      await pumpAndSettle();
    }
  }

  Future<void> createOpenRenameDocumentUnderParent({
    required String name,
    String? parentName,
  }) async {
    // create a new page
    await tapAddViewButton(name: parentName ?? gettingStarted);
    await tapButtonWithName(ViewLayoutPB.Document.menuName);
    final settingsOrFailure = await getIt<KeyValueStorage>().getWithFormat(
      KVKeys.showRenameDialogWhenCreatingNewFile,
      (value) => bool.parse(value),
    );
    final showRenameDialog = settingsOrFailure ?? false;
    if (showRenameDialog) {
      await tapOKButton();
    }
    await pumpAndSettle();

    // open the page after created
    await openPage(ViewLayoutPB.Document.defaultName);
    await pumpAndSettle();

    // Enter new name in the document title
    await enterText(find.byType(TextFieldWithMetricLines), name);
    await pumpAndSettle();
  }

  /// Create a new page in the space
  Future<void> createNewPageInSpace({
    required String spaceName,
    required ViewLayoutPB layout,
    bool openAfterCreated = true,
    String? pageName,
  }) async {
    final currentSpace = find.byWidgetPredicate(
      (widget) => widget is CurrentSpace && widget.space.name == spaceName,
    );
    if (currentSpace.evaluate().isEmpty) {
      throw Exception('Current space not found');
    }

    await hoverOnWidget(
      currentSpace,
      onHover: () async {
        // click the + button
        await clickAddPageButtonInSpaceHeader();
        await tapButtonWithName(layout.menuName);
      },
    );
    await pumpAndSettle();

    if (pageName != null) {
      // move the cursor to other place to disable to tooltips
      await tapAt(Offset.zero);

      // hover on new created page and change it's name
      await hoverOnPageName(
        '',
        layout: layout,
        onHover: () async {
          await renamePage(pageName);
          await pumpAndSettle();
        },
      );
      await pumpAndSettle();
    }

    // open the page after created
    if (openAfterCreated) {
      // if the name is null, use empty string
      await openPage(pageName ?? '', layout: layout);
      await pumpAndSettle();
    }
  }

  /// Click the + button in the space header
  Future<void> clickAddPageButtonInSpaceHeader() async {
    final addPageButton = find.descendant(
      of: find.byType(SidebarSpaceHeader),
      matching: find.byType(ViewAddButton),
    );
    await tapButton(addPageButton);
  }

  /// Click the + button in the space header
  Future<void> clickSpaceHeader() async {
    await tapButton(find.byType(SidebarSpaceHeader));
  }

  Future<void> openSpace(String spaceName) async {
    final space = find.descendant(
      of: find.byType(SidebarSpaceMenuItem),
      matching: find.text(spaceName),
    );
    await tapButton(space);
  }

  /// Create a new page on the top level
  Future<void> createNewPage({
    ViewLayoutPB layout = ViewLayoutPB.Document,
    bool openAfterCreated = true,
  }) async {
    await tapButton(find.byType(SidebarNewPageButton));
  }

  Future<void> simulateKeyEvent(
    LogicalKeyboardKey key, {
    bool isControlPressed = false,
    bool isShiftPressed = false,
    bool isAltPressed = false,
    bool isMetaPressed = false,
    PhysicalKeyboardKey? physicalKey,
  }) async {
    if (isControlPressed) {
      await simulateKeyDownEvent(LogicalKeyboardKey.control);
    }
    if (isShiftPressed) {
      await simulateKeyDownEvent(LogicalKeyboardKey.shift);
    }
    if (isAltPressed) {
      await simulateKeyDownEvent(LogicalKeyboardKey.alt);
    }
    if (isMetaPressed) {
      await simulateKeyDownEvent(LogicalKeyboardKey.meta);
    }
    await simulateKeyDownEvent(
      key,
      physicalKey: physicalKey,
    );
    await simulateKeyUpEvent(
      key,
      physicalKey: physicalKey,
    );
    if (isControlPressed) {
      await simulateKeyUpEvent(LogicalKeyboardKey.control);
    }
    if (isShiftPressed) {
      await simulateKeyUpEvent(LogicalKeyboardKey.shift);
    }
    if (isAltPressed) {
      await simulateKeyUpEvent(LogicalKeyboardKey.alt);
    }
    if (isMetaPressed) {
      await simulateKeyUpEvent(LogicalKeyboardKey.meta);
    }
    await pumpAndSettle();
  }

  Future<void> openAppInNewTab(String name, ViewLayoutPB layout) async {
    await hoverOnPageName(
      name,
      onHover: () async {
        await tapOpenInTabButton();
        await pumpAndSettle();
      },
    );
    await pumpAndSettle();
  }

  Future<void> favoriteViewByName(
    String name, {
    ViewLayoutPB layout = ViewLayoutPB.Document,
  }) async {
    await hoverOnPageName(
      name,
      layout: layout,
      onHover: () async {
        await tapFavoritePageButton();
        await pumpAndSettle();
      },
    );
  }

  Future<void> unfavoriteViewByName(
    String name, {
    ViewLayoutPB layout = ViewLayoutPB.Document,
  }) async {
    await hoverOnPageName(
      name,
      layout: layout,
      onHover: () async {
        await tapUnfavoritePageButton();
        await pumpAndSettle();
      },
    );
  }

  Future<void> movePageToOtherPage({
    required String name,
    required String parentName,
    required ViewLayoutPB layout,
    required ViewLayoutPB parentLayout,
    DraggableHoverPosition position = DraggableHoverPosition.center,
  }) async {
    final from = findPageName(name, layout: layout);
    final to = findPageName(parentName, layout: parentLayout);
    final gesture = await startGesture(getCenter(from));
    Offset offset = Offset.zero;
    switch (position) {
      case DraggableHoverPosition.center:
        offset = getCenter(to);
        break;
      case DraggableHoverPosition.top:
        offset = getTopLeft(to);
        break;
      case DraggableHoverPosition.bottom:
        offset = getBottomLeft(to);
        break;
      default:
    }
    await gesture.moveTo(offset, timeStamp: const Duration(milliseconds: 400));
    await gesture.up();
    await pumpAndSettle();
  }

  Future<void> reorderFavorite({
    required String fromName,
    required String toName,
  }) async {
    final from = find.descendant(
          of: find.byType(FavoriteFolder),
          matching: find.text(fromName),
        ),
        to = find.descendant(
          of: find.byType(FavoriteFolder),
          matching: find.text(toName),
        );
    final distanceY = getCenter(to).dy - getCenter(from).dx;
    await drag(from, Offset(0, distanceY));
    await pumpAndSettle(const Duration(seconds: 1));
  }

  // tap the button with [FlowySvgData]
  Future<void> tapButtonWithFlowySvgData(FlowySvgData svg) async {
    final button = find.byWidgetPredicate(
      (widget) => widget is FlowySvg && widget.svg.path == svg.path,
    );
    await tapButton(button);
  }

  // update the page icon in the sidebar
  Future<void> updatePageIconInSidebarByName({
    required String name,
    String? parentName,
    required ViewLayoutPB layout,
    required EmojiIconData icon,
  }) async {
    final iconButton = find.descendant(
      of: findPageName(
        name,
        layout: layout,
        parentName: parentName,
      ),
      matching:
          find.byTooltip(LocaleKeys.document_plugins_cover_changeIcon.tr()),
    );
    await tapButton(iconButton);
    if (icon.type == FlowyIconType.emoji) {
      await tapEmoji(icon.emoji);
    } else if (icon.type == FlowyIconType.icon) {
      await tapIcon(icon);
    }
    await pumpAndSettle();
  }

  // update the page icon in the sidebar
  Future<void> updatePageIconInTitleBarByName({
    required String name,
    required ViewLayoutPB layout,
    required EmojiIconData icon,
  }) async {
    await openPage(
      name,
      layout: layout,
    );
    final title = find.descendant(
      of: find.byType(ViewTitleBar),
      matching: find.text(name),
    );
    await tapButton(title);
    await tapButton(find.byType(EmojiPickerButton));
    if (icon.type == FlowyIconType.emoji) {
      await tapEmoji(icon.emoji);
    } else if (icon.type == FlowyIconType.icon) {
      await tapIcon(icon);
    } else if (icon.type == FlowyIconType.custom) {
      await pickImage(icon);
    }
    await pumpAndSettle();
  }

  Future<void> updatePageIconInTitleBarByPasteALink({
    required String name,
    required ViewLayoutPB layout,
    required String iconLink,
  }) async {
    await openPage(
      name,
      layout: layout,
    );
    final title = find.descendant(
      of: find.byType(ViewTitleBar),
      matching: find.text(name),
    );
    await tapButton(title);
    await tapButton(find.byType(EmojiPickerButton));
    await pasteImageLinkAsIcon(iconLink);
    await pumpAndSettle();
  }

  Future<void> openNotificationHub({int tabIndex = 0}) async {
    final finder = find.descendant(
      of: find.byType(NotificationButton),
      matching: find.byWidgetPredicate(
        (widget) => widget is FlowySvg && widget.svg == FlowySvgs.clock_alarm_s,
      ),
    );

    await tap(finder);
    await pumpAndSettle();

    if (tabIndex == 1) {
      final tabFinder = find.descendant(
        of: find.byType(NotificationTabBar),
        matching: find.byType(FlowyTabItem).at(1),
      );

      await tap(tabFinder);
      await pumpAndSettle();
    }
  }

  Future<void> toggleCommandPalette() async {
    // Press CMD+P or CTRL+P to open the command palette
    await simulateKeyEvent(
      LogicalKeyboardKey.keyP,
      isControlPressed: !Platform.isMacOS,
      isMetaPressed: Platform.isMacOS,
    );
    await pumpAndSettle();
  }

  Future<void> openCollaborativeWorkspaceMenu() async {
    if (!FeatureFlag.collaborativeWorkspace.isOn) {
      throw UnsupportedError('Collaborative workspace is not enabled');
    }

    final workspace = find.byType(SidebarWorkspace);
    expect(workspace, findsOneWidget);

    await tapButton(workspace, milliseconds: 5000);
  }

  Future<void> createCollaborativeWorkspace(String name) async {
    if (!FeatureFlag.collaborativeWorkspace.isOn) {
      throw UnsupportedError('Collaborative workspace is not enabled');
    }
    await openCollaborativeWorkspaceMenu();
    // expect to see the workspace list, and there should be only one workspace
    final workspacesMenu = find.byType(WorkspacesMenu);
    expect(workspacesMenu, findsOneWidget);

    // click the create button
    final createButton = find.byKey(createWorkspaceButtonKey);
    expect(createButton, findsOneWidget);
    await tapButton(createButton);

    // input the workspace name
    final workspaceNameInput = find.descendant(
      of: find.byType(AFTextFieldDialog),
      matching: find.byType(TextField),
    );
    await enterText(workspaceNameInput, name);
    await pumpAndSettle();

    await tapButton(
      find.text(LocaleKeys.button_confirm.tr()),
      milliseconds: 2000,
    );
  }

  // For mobile platform to launch the app in anonymous mode
  Future<void> launchInAnonymousMode() async {
    assert(
      [TargetPlatform.android, TargetPlatform.iOS]
          .contains(defaultTargetPlatform),
      'This method is only supported on mobile platforms',
    );

    await initializeAppFlowy();

    final anonymousSignInButton = find.byType(SignInAnonymousButtonV2);
    expect(anonymousSignInButton, findsOneWidget);
    await tapButton(anonymousSignInButton);

    await pumpUntilFound(find.byType(MobileHomeScreen));
  }

  Future<void> tapSvgButton(FlowySvgData svg) async {
    final button = find.byWidgetPredicate(
      (widget) => widget is FlowySvg && widget.svg.path == svg.path,
    );
    await tapButton(button);
  }

  Future<void> openMoreViewActions() async {
    final button = find.byType(MoreViewActions);
    await tapButton(button);
  }

  /// Presses on the Duplicate ViewAction in the [MoreViewActions] popup.
  ///
  /// [openMoreViewActions] must be called beforehand!
  ///
  Future<void> duplicateByMoreViewActions() async {
    final button = find.byWidgetPredicate(
      (widget) =>
          widget is ViewAction && widget.type == ViewMoreActionType.duplicate,
    );
    await tap(button);
    await pump();
  }

  /// Presses on the Delete ViewAction in the [MoreViewActions] popup.
  ///
  /// [openMoreViewActions] must be called beforehand!
  ///
  Future<void> deleteByMoreViewActions() async {
    final button = find.descendant(
      of: find.byType(ListView),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is ViewAction && widget.type == ViewMoreActionType.delete,
      ),
    );
    await tap(button);
    await pump();
  }

  Future<void> tapFileUploadHint() async {
    final finder = find.byWidgetPredicate(
      (w) =>
          w is RichText &&
          w.text.toPlainText().contains(
                LocaleKeys.document_plugins_file_fileUploadHint.tr(),
              ),
    );
    await tap(finder);
    await pumpAndSettle(const Duration(seconds: 2));
  }

  /// Create a new document on mobile
  Future<void> createNewDocumentOnMobile(String name) async {
    final createPageButton = find.byKey(
      BottomNavigationBarItemType.add.valueKey,
    );
    await tapButton(createPageButton);
    expect(find.byType(MobileDocumentScreen), findsOneWidget);

    final title = editor.findDocumentTitle('');
    expect(title, findsOneWidget);
    final textField = widget<TextField>(title);
    expect(textField.focusNode!.hasFocus, isTrue);

    // input new name and press done button
    await enterText(title, name);
    await testTextInput.receiveAction(TextInputAction.done);
    await pumpAndSettle();
    final newTitle = editor.findDocumentTitle(name);
    expect(newTitle, findsOneWidget);
    expect(textField.controller!.text, name);
  }

  /// Open the plus menu
  Future<void> openPlusMenuAndClickButton(String buttonName) async {
    assert(
      UniversalPlatform.isMobile,
      'This method is only supported on mobile platforms',
    );

    final plusMenuButton = find.byKey(addBlockToolbarItemKey);
    final addMenuItem = find.byType(AddBlockMenu);
    await tapButton(plusMenuButton);
    await pumpUntilFound(addMenuItem);

    final toggleHeading1 = find.byWidgetPredicate(
      (widget) =>
          widget is TypeOptionMenuItem && widget.value.text == buttonName,
    );
    final scrollable = find.ancestor(
      of: find.byType(TypeOptionGridView),
      matching: find.byType(Scrollable),
    );
    await scrollUntilVisible(
      toggleHeading1,
      100,
      scrollable: scrollable,
    );
    await tapButton(toggleHeading1);
    await pumpUntilNotFound(addMenuItem);
  }

  /// Click the column menu button in the simple table
  Future<void> clickColumnMenuButton(int index) async {
    final columnMenuButton = find.byWidgetPredicate(
      (w) =>
          w is SimpleTableMobileReorderButton &&
          w.index == index &&
          w.type == SimpleTableMoreActionType.column,
    );
    await tapButton(columnMenuButton);
    await pumpUntilFound(find.byType(SimpleTableCellBottomSheet));
  }

  /// Click the row menu button in the simple table
  Future<void> clickRowMenuButton(int index) async {
    final rowMenuButton = find.byWidgetPredicate(
      (w) =>
          w is SimpleTableMobileReorderButton &&
          w.index == index &&
          w.type == SimpleTableMoreActionType.row,
    );
    await tapButton(rowMenuButton);
    await pumpUntilFound(find.byType(SimpleTableCellBottomSheet));
  }

  /// Click the SimpleTableQuickAction
  Future<void> clickSimpleTableQuickAction(SimpleTableMoreAction action) async {
    final button = find.byWidgetPredicate(
      (widget) => widget is SimpleTableQuickAction && widget.type == action,
    );
    await tapButton(button);
  }

  /// Click the SimpleTableContentAction
  Future<void> clickSimpleTableBoldContentAction() async {
    final button = find.byType(SimpleTableContentBoldAction);
    await tapButton(button);
  }

  /// Cancel the table action menu
  Future<void> cancelTableActionMenu() async {
    final finder = find.byType(SimpleTableCellBottomSheet);
    if (finder.evaluate().isEmpty) {
      return;
    }

    await tapAt(Offset.zero);
    await pumpUntilNotFound(finder);
  }

  /// load icon list and return the first one
  Future<EmojiIconData> loadIcon() async {
    await loadIconGroups();
    final groups = kIconGroups!;
    final firstGroup = groups.first;
    final firstIcon = firstGroup.icons.first;
    return EmojiIconData.icon(
      IconsData(
        firstGroup.name,
        firstIcon.name,
        builtInSpaceColors.first,
      ),
    );
  }

  Future<EmojiIconData> prepareImageIcon() async {
    final imagePath = await rootBundle.load('assets/test/images/sample.jpeg');
    final tempDirectory = await getTemporaryDirectory();
    final localImagePath = p.join(tempDirectory.path, 'sample.jpeg');
    final imageFile = File(localImagePath)
      ..writeAsBytesSync(imagePath.buffer.asUint8List());
    return EmojiIconData.custom(imageFile.path);
  }

  Future<EmojiIconData> prepareSvgIcon() async {
    final imagePath = await rootBundle.load('assets/test/images/sample.svg');
    final tempDirectory = await getTemporaryDirectory();
    final localImagePath = p.join(tempDirectory.path, 'sample.svg');
    final imageFile = File(localImagePath)
      ..writeAsBytesSync(imagePath.buffer.asUint8List());
    return EmojiIconData.custom(imageFile.path);
  }

  /// create new page and show slash menu
  Future<void> createPageAndShowSlashMenu(String title) async {
    await createNewDocumentOnMobile(title);
    await editor.tapLineOfEditorAt(0);
    await editor.showSlashMenu();
  }

  /// create new page and show at menu
  Future<void> createPageAndShowAtMenu(String title) async {
    await createNewDocumentOnMobile(title);
    await editor.tapLineOfEditorAt(0);
    await editor.showAtMenu();
  }

  /// create new page and show plus menu
  Future<void> createPageAndShowPlusMenu(String title) async {
    await createNewDocumentOnMobile(title);
    await editor.tapLineOfEditorAt(0);
    await editor.showPlusMenu();
  }
}

extension SettingsFinder on CommonFinders {
  Finder findSettingsScrollable() => find
      .descendant(
        of: find
            .descendant(
              of: find.byType(SettingsBody),
              matching: find.byType(SingleChildScrollView),
            )
            .first,
        matching: find.byType(Scrollable),
      )
      .first;

  Finder findSettingsMenuScrollable() => find
      .descendant(
        of: find
            .descendant(
              of: find.byType(SettingsMenu),
              matching: find.byType(SingleChildScrollView),
            )
            .first,
        matching: find.byType(Scrollable),
      )
      .first;
}

extension FlowySvgFinder on CommonFinders {
  Finder byFlowySvg(FlowySvgData svg) => _FlowySvgFinder(svg);
}

class _FlowySvgFinder extends MatchFinder {
  _FlowySvgFinder(this.svg);

  final FlowySvgData svg;

  @override
  String get description => 'flowy_svg "$svg"';

  @override
  bool matches(Element candidate) {
    final Widget widget = candidate.widget;
    return widget is FlowySvg && widget.svg == svg;
  }
}

extension ViewLayoutPBTest on ViewLayoutPB {
  String get menuName {
    switch (this) {
      case ViewLayoutPB.Grid:
        return LocaleKeys.grid_menuName.tr();
      case ViewLayoutPB.Board:
        return LocaleKeys.board_menuName.tr();
      case ViewLayoutPB.Document:
        return LocaleKeys.document_menuName.tr();
      case ViewLayoutPB.Calendar:
        return LocaleKeys.calendar_menuName.tr();
      case ViewLayoutPB.Chat:
        return LocaleKeys.chat_newChat.tr();
      default:
        throw UnsupportedError('Unsupported layout: $this');
    }
  }

  String get referencedMenuName {
    switch (this) {
      case ViewLayoutPB.Grid:
        return LocaleKeys.document_plugins_referencedGrid.tr();
      case ViewLayoutPB.Board:
        return LocaleKeys.document_plugins_referencedBoard.tr();
      case ViewLayoutPB.Calendar:
        return LocaleKeys.document_plugins_referencedCalendar.tr();
      default:
        throw UnsupportedError('Unsupported layout: $this');
    }
  }

  String get slashMenuName {
    switch (this) {
      case ViewLayoutPB.Grid:
        return LocaleKeys.document_slashMenu_name_grid.tr();
      case ViewLayoutPB.Board:
        return LocaleKeys.document_slashMenu_name_kanban.tr();
      case ViewLayoutPB.Document:
        return LocaleKeys.document_slashMenu_name_doc.tr();
      case ViewLayoutPB.Calendar:
        return LocaleKeys.document_slashMenu_name_calendar.tr();
      default:
        throw UnsupportedError('Unsupported layout: $this');
    }
  }

  String get slashMenuLinkedName {
    switch (this) {
      case ViewLayoutPB.Grid:
        return LocaleKeys.document_slashMenu_name_linkedGrid.tr();
      case ViewLayoutPB.Board:
        return LocaleKeys.document_slashMenu_name_linkedKanban.tr();
      case ViewLayoutPB.Document:
        return LocaleKeys.document_slashMenu_name_linkedDoc.tr();
      case ViewLayoutPB.Calendar:
        return LocaleKeys.document_slashMenu_name_linkedCalendar.tr();
      default:
        throw UnsupportedError('Unsupported layout: $this');
    }
  }
}
