import 'package:flutter/material.dart';
import 'package:flutter_screen_lock/buttons/customizable_button.dart';
import 'package:flutter_screen_lock/buttons/hidden_button.dart';
import 'package:flutter_screen_lock/buttons/input_button.dart';
import 'package:flutter_screen_lock/configurations/input_button_config.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/views/widgets/modals/modal-lock-overlay/lock-buttons.dart';
import 'package:syphon/views/widgets/modals/modal-lock-overlay/lock-controller.dart';

/// In order to arrange the buttons neatly by their size,
/// I dared to adjust them without using GridView or Wrap.
/// If you use GridView, you have to specify the overall width to adjust the size of the button,
/// which makes it difficult to specify the size intuitively.
class KeyPad extends StatelessWidget {
  const KeyPad({
    Key? key,
    required this.lockController,
    required this.canCancel,
    this.inputButtonConfig = const InputButtonConfig(),
    this.rightButtonChild,
    this.onLeftButtonTap,
    this.deleteButton,
    this.cancelButton,
  }) : super(key: key);

  final LockController lockController;
  final bool canCancel;
  final InputButtonConfig inputButtonConfig;
  final Widget? rightButtonChild;
  final Future<void> Function()? onLeftButtonTap;
  final Widget? cancelButton;
  final Widget? deleteButton;

  Widget _buildLeftSideButton() {
    return StreamBuilder<String>(
      stream: lockController.currentInput,
      builder: (context, snapshot) {
        if ((snapshot.hasData == false || snapshot.data!.isEmpty) && canCancel) {
          return CustomizableButton(
            onPressed: onLeftButtonTap == null ? () => false : () => onLeftButtonTap!(),
            child: const Icon(
              Icons.cancel,
              size: Dimensions.iconSizeLarge,
            ),
          );
        } else {
          return CustomizableButton(
            onPressed: () => lockController.removeCharacter(),
            child: const Icon(
              Icons.backspace,
              size: Dimensions.iconSizeLarge,
            ),
          );
        }
      },
    );
  }

  Widget _buildRightSideButton() {
    return StreamBuilder<bool>(
      stream: lockController.loading,
      builder: (context, loadingData) => StreamBuilder<String>(
        stream: lockController.currentInput,
        builder: (context, currentInput) {
          final loading = loadingData.data ?? false;

          if (currentInput.hasData == false || currentInput.data!.isEmpty) {
            return HiddenButton();
          } else {
            return LockButton(
              disabled: loading,
              onPressed: () => lockController.verify(),
              child: const Icon(
                Icons.check_circle,
                size: Dimensions.iconSizeLarge,
              ),
            );
          }
        },
      ),
    );
  }

  Widget _generateRow(BuildContext context, int rowNumber) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final number = (rowNumber - 1) * 3 + index + 1;
        final input = inputButtonConfig.inputStrings[number];
        final display = inputButtonConfig.displayStrings[number];

        return InputButton(
          config: inputButtonConfig,
          onPressed: () => lockController.addCharacter(input),
          displayText: display,
        );
      }),
    );
  }

  Widget _generateLastRow(BuildContext context) {
    final input = inputButtonConfig.inputStrings[0];
    final display = inputButtonConfig.displayStrings[0];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLeftSideButton(),
        InputButton(
          config: inputButtonConfig,
          onPressed: () => lockController.addCharacter(input),
          displayText: display,
        ),
        _buildRightSideButton(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(inputButtonConfig.displayStrings.length == 10);
    assert(inputButtonConfig.inputStrings.length == 10);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _generateRow(context, 1),
        _generateRow(context, 2),
        _generateRow(context, 3),
        _generateLastRow(context),
      ],
    );
  }
}
