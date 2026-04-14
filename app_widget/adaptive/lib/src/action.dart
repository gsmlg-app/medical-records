import 'package:duskmoon_widgets/duskmoon_widgets.dart';
import 'package:flutter/material.dart';

export 'package:duskmoon_adaptive_scaffold/duskmoon_adaptive_scaffold.dart';

enum AppAdaptiveActionSize {
  small,
  medium,
  large,
}

class AppAdaptiveAction {
  final String title;
  final IconData icon;
  final void Function() onPressed;
  final bool disabled;

  AppAdaptiveAction({
    required this.title,
    required this.icon,
    required this.onPressed,
    this.disabled = false,
  });
}

class AppAdaptiveActionList extends StatelessWidget {
  final AppAdaptiveActionSize size;
  final List<AppAdaptiveAction> actions;
  final Axis direction;
  final bool hideDisabled;

  AppAdaptiveActionList({
    super.key,
    this.size = AppAdaptiveActionSize.medium,
    required List<AppAdaptiveAction> actions,
    this.hideDisabled = true,
    this.direction = Axis.horizontal,
  }) : actions = hideDisabled
            ? actions.where((action) => !action.disabled).toList()
            : actions;

  @override
  Widget build(BuildContext context) {
    switch (size) {
      case AppAdaptiveActionSize.small:
        return PopupMenuButton<int>(
          itemBuilder: (context) => actions
              .map<PopupMenuEntry<int>>(
                (action) => PopupMenuItem(
                  value: actions.indexOf(action),
                  child: Text.rich(
                    TextSpan(children: [
                      WidgetSpan(
                          child: Icon(action.icon,
                              color: action.disabled
                                  ? Theme.of(context).disabledColor
                                  : Theme.of(context).iconTheme.color)),
                      const TextSpan(text: ' '),
                      TextSpan(text: action.title),
                    ]),
                  ),
                ),
              )
              .toList(),
          onSelected: (value) {
            if (actions[value].disabled) return;
            actions[value].onPressed();
          },
        );

      case AppAdaptiveActionSize.medium:
        return Wrap(
          direction: direction,
          children: actions
              .map<Widget>(
                (action) => DmIconButton(
                  icon: Icon(action.icon),
                  tooltip: action.title,
                  onPressed: action.disabled ? null : action.onPressed,
                ),
              )
              .toList(),
        );

      case AppAdaptiveActionSize.large:
        return Wrap(
          direction: direction,
          children: actions
              .map<Widget>(
                (action) => DmButton(
                  variant: DmButtonVariant.text,
                  onPressed: action.disabled ? null : action.onPressed,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(action.icon),
                      const SizedBox(width: 8),
                      Text(action.title),
                    ],
                  ),
                ),
              )
              .toList(),
        );
    }
  }
}
