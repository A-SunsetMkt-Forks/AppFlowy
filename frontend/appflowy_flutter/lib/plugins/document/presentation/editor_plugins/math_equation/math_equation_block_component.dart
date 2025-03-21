import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/mobile_block_action_buttons.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/block_menu/block_menu_button.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/buttons/primary_button.dart';
import 'package:flowy_infra_ui/widget/buttons/secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';

class MathEquationBlockKeys {
  const MathEquationBlockKeys._();

  static const String type = 'math_equation';

  /// The content of a math equation block.
  ///
  /// The value is a String.
  static const String formula = 'formula';
}

Node mathEquationNode({
  String formula = '',
}) {
  final attributes = {
    MathEquationBlockKeys.formula: formula,
  };
  return Node(
    type: MathEquationBlockKeys.type,
    attributes: attributes,
  );
}

// defining the callout block menu item for selection
SelectionMenuItem mathEquationItem = SelectionMenuItem.node(
  getName: LocaleKeys.document_plugins_mathEquation_name.tr,
  iconBuilder: (editorState, onSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.icon_math_eq_s,
    isSelected: onSelected,
    style: style,
  ),
  keywords: ['tex, latex, katex', 'math equation', 'formula'],
  nodeBuilder: (editorState, _) => mathEquationNode(),
  replace: (_, node) => node.delta?.isEmpty ?? false,
  updateSelection: (editorState, path, __, ___) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final mathEquationState =
          editorState.getNodeAtPath(path)?.key.currentState;
      if (mathEquationState != null &&
          mathEquationState is MathEquationBlockComponentWidgetState) {
        mathEquationState.showEditingDialog();
      }
    });
    return null;
  },
);

class MathEquationBlockComponentBuilder extends BlockComponentBuilder {
  MathEquationBlockComponentBuilder({
    super.configuration,
  });

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return MathEquationBlockComponentWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      showActions: showActions(node),
      actionBuilder: (context, state) => actionBuilder(
        blockComponentContext,
        state,
      ),
      actionTrailingBuilder: (context, state) => actionTrailingBuilder(
        blockComponentContext,
        state,
      ),
    );
  }

  @override
  BlockComponentValidate get validate => (node) =>
      node.children.isEmpty &&
      node.attributes[MathEquationBlockKeys.formula] is String;
}

class MathEquationBlockComponentWidget extends BlockComponentStatefulWidget {
  const MathEquationBlockComponentWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.actionTrailingBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<MathEquationBlockComponentWidget> createState() =>
      MathEquationBlockComponentWidgetState();
}

class MathEquationBlockComponentWidgetState
    extends State<MathEquationBlockComponentWidget>
    with BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  String get formula =>
      widget.node.attributes[MathEquationBlockKeys.formula] as String;

  late final editorState = context.read<EditorState>();
  final ValueNotifier<bool> isHover = ValueNotifier(false);

  late final controller = TextEditingController(text: formula);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onHover: (value) => isHover.value = value,
      onTap: showEditingDialog,
      child: _build(context),
    );
  }

  Widget _build(BuildContext context) {
    Widget child = Container(
      constraints: const BoxConstraints(minHeight: 52),
      decoration: BoxDecoration(
        color: formula.isNotEmpty
            ? Colors.transparent
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FlowyHover(
        style: HoverStyle(
          borderRadius: BorderRadius.circular(4),
        ),
        child: formula.isEmpty
            ? _buildPlaceholderWidget(context)
            : _buildMathEquation(context),
      ),
    );

    if (widget.showActions && widget.actionBuilder != null) {
      child = BlockComponentActionWrapper(
        node: node,
        actionBuilder: widget.actionBuilder!,
        actionTrailingBuilder: widget.actionTrailingBuilder,
        child: child,
      );
    }

    if (UniversalPlatform.isMobile) {
      child = MobileBlockActionButtons(
        node: node,
        editorState: editorState,
        child: child,
      );
    }

    child = Padding(
      padding: padding,
      child: child,
    );

    if (UniversalPlatform.isDesktopOrWeb) {
      child = Stack(
        children: [
          child,
          Positioned(
            right: 6,
            top: 12,
            child: ValueListenableBuilder<bool>(
              valueListenable: isHover,
              builder: (_, value, __) =>
                  value ? _buildDeleteButton(context) : const SizedBox.shrink(),
            ),
          ),
        ],
      );
    }

    return child;
  }

  Widget _buildPlaceholderWidget(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          const HSpace(10),
          FlowySvg(
            FlowySvgs.slash_menu_icon_math_equation_s,
            color: Theme.of(context).hintColor,
            size: const Size.square(24),
          ),
          const HSpace(10),
          FlowyText(
            LocaleKeys.document_plugins_mathEquation_addMathEquation.tr(),
            color: Theme.of(context).hintColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMathEquation(BuildContext context) {
    return Center(
      child: Math.tex(
        formula,
        textStyle: const TextStyle(fontSize: 20),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return MenuBlockButton(
      tooltip: LocaleKeys.button_delete.tr(),
      iconData: FlowySvgs.trash_s,
      onTap: () {
        final transaction = editorState.transaction..deleteNode(widget.node);
        editorState.apply(transaction);
      },
    );
  }

  void showEditingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).canvasColor,
          title: Text(
            LocaleKeys.document_plugins_mathEquation_editMathEquation.tr(),
          ),
          content: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (key) {
              if (key.logicalKey == LogicalKeyboardKey.enter &&
                  !HardwareKeyboard.instance.isShiftPressed) {
                updateMathEquation(controller.text, context);
              } else if (key.logicalKey == LogicalKeyboardKey.escape) {
                dismiss(context);
              }
            },
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.3,
              child: TextField(
                autofocus: true,
                controller: controller,
                maxLines: null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'E = MC^2',
                ),
              ),
            ),
          ),
          actions: [
            SecondaryTextButton(
              LocaleKeys.button_cancel.tr(),
              mode: TextButtonMode.big,
              onPressed: () => dismiss(context),
            ),
            PrimaryTextButton(
              LocaleKeys.button_done.tr(),
              onPressed: () => updateMathEquation(controller.text, context),
            ),
          ],
          actionsPadding: const EdgeInsets.only(bottom: 20),
          actionsAlignment: MainAxisAlignment.spaceAround,
        );
      },
    );
  }

  void updateMathEquation(String mathEquation, BuildContext context) {
    if (mathEquation == formula) {
      dismiss(context);
      return;
    }
    final transaction = editorState.transaction
      ..updateNode(
        widget.node,
        {
          MathEquationBlockKeys.formula: mathEquation,
        },
      );
    editorState.apply(transaction);
    dismiss(context);
  }

  void dismiss(BuildContext context) {
    Navigator.of(context).pop();
  }
}
