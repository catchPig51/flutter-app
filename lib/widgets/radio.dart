import 'package:flutter/widgets.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_svg/svg.dart';

import 'brightness_observer.dart';

class RadioItem<T> extends StatelessWidget {
  const RadioItem({
    Key? key,
    required this.title,
    this.groupValue,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  final Widget title;
  final T? groupValue;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              ClipOval(
                child: Container(
                  color: groupValue == value
                      ? BrightnessData.themeOf(context).accent
                      : BrightnessData.themeOf(context).secondaryText,
                  height: 16,
                  width: 16,
                  alignment: const Alignment(0.0, -0.2),
                  child: SvgPicture.asset(
                    Resources.assetsImagesSelectedSvg,
                    height: 10,
                    width: 10,
                  ),
                ),
              ),
              const SizedBox(width: 30),
              DefaultTextStyle(
                style: TextStyle(
                  color: BrightnessData.themeOf(context).text,
                  fontSize: 16,
                ),
                child: title,
              ),
            ],
          ),
        ),
      );
}