import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:syphon/domain/auth/actions.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/views/widgets/loader/loading-indicator.dart';

class DialogTextInput extends HookWidget {
  const DialogTextInput({
    super.key,
    this.title = '',
    this.content = '',
    this.label = '',
    this.initialValue = '',
    this.loading = false,
    this.valid = false,
    this.obscureText = false,
    this.randomizeText = false,
    this.confirmText = '',
    this.keyboardType = TextInputType.text,
    this.inputFormatters = const [],
    this.editingController,
    this.onConfirm,
    this.onChange,
    this.onCancel,
  });

  final String title;
  final String content;
  final String label;
  final String initialValue;
  final String confirmText;

  final bool obscureText;
  final bool randomizeText;

  final bool valid;
  final bool loading;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final TextEditingController? editingController;

  final Function? onChange;
  final Function? onConfirm;
  final Function? onCancel;

  @override
  Widget build(BuildContext context) {
    final editingControllerLocal = editingController ?? useTextEditingController(text: initialValue);

    final inputFocusNode = useFocusNode();

    final isEmpty = useState<bool>(editingControllerLocal.text.isEmpty);
    final visibility = useState<bool>(true);
    final loadingLocal = useState<bool>(loading);

    useEffect(() {
      editingControllerLocal.addListener(() {
        isEmpty.value = editingControllerLocal.text.isEmpty;
      });

      return null;
    }, []);

    final width = MediaQuery.of(context).size.width;
    final defaultWidgetScaling = useMemoized(() => width * 0.725, [width]);
    final loadingAny = loadingLocal.value || loading;

    final suffix = useMemoized(
      () {
        if (randomizeText) {
          return GestureDetector(
            onTap: () async {
              editingControllerLocal.text = generateDeviceId().deviceId ?? '';
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Icon(
                const FaIcon(FontAwesomeIcons.dice).icon,
                color: Theme.of(context).primaryColor,
              ),
            ),
          );
        }

        if (obscureText) {
          return GestureDetector(
            onTap: () {
              visibility.value = !visibility.value;
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Icon(
                visibility.value ? Icons.visibility : Icons.visibility_off,
                color: visibility.value ? Theme.of(context).primaryColor : null,
              ),
            ),
          );
        }
      },
      [obscureText, randomizeText],
    );

    return SimpleDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titlePadding: const EdgeInsets.only(
        left: 24,
        right: 16,
        top: 16,
      ),
      contentPadding: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16,
      ),
      title: Text(title),
      children: <Widget>[
        Column(
          children: <Widget>[
            Container(
              width: defaultWidgetScaling,
              margin: const EdgeInsets.only(
                top: 16,
                bottom: 16,
                left: 8,
              ),
              child: Text(
                content,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Container(
              width: defaultWidgetScaling,
              height: Dimensions.inputHeight,
              margin: const EdgeInsets.only(
                top: 12,
                bottom: 20,
              ),
              constraints: const BoxConstraints(
                minWidth: Dimensions.inputWidthMin,
                maxWidth: Dimensions.inputWidthMax,
              ),
              child: TextField(
                enabled: !loadingAny,
                focusNode: inputFocusNode,
                controller: editingControllerLocal,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                obscureText: obscureText && (!visibility.value || loadingAny),
                decoration: InputDecoration(
                  suffix: suffix,
                  contentPadding: EdgeInsets.only(
                    left: 20,
                    right: suffix == null ? 0 : 20,
                    bottom: 32,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  labelText: label,
                ),
                onChanged: (value) {
                  onChange?.call(value);
                },
                onSubmitted: (value) {
                  onConfirm?.call(value);
                },
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            TextButton(
              onPressed: loadingAny ? null : () => onCancel?.call(),
              child: Text(Strings.buttonCancel),
            ),
            TextButton(
              onPressed: loadingAny || isEmpty.value
                  ? null
                  : () async {
                      if (onConfirm != null && !isEmpty.value) {
                        inputFocusNode.unfocus();
                        loadingLocal.value = true;
                        visibility.value = false;
                        await onConfirm!(editingControllerLocal.text);
                        loadingLocal.value = false;
                      }
                    },
              child: !loadingAny
                  ? Text(confirmText.isEmpty ? Strings.buttonSave : confirmText)
                  : const LoadingIndicator(size: 16),
            ),
          ],
        )
      ],
    );
  }
}
