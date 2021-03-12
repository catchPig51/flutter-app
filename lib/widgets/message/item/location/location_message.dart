import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/utils/uri_utils.dart';
import 'package:flutter_app/widgets/cache_image.dart';
import 'package:flutter_svg/svg.dart';
import 'package:map/map.dart';
import 'package:latlng/latlng.dart';

import '../../../interacter_decorated_box.dart';
import '../../message_bubble.dart';
import '../../message_datetime.dart';
import '../../message_status.dart';
import 'location_payload.dart';

class LocationMessage extends StatelessWidget {
  const LocationMessage({
    Key? key,
    required this.message,
    required this.showNip,
    required this.isCurrentUser,
  }) : super(key: key);

  final bool showNip;
  final bool isCurrentUser;
  final MessageItem message;

  @override
  Widget build(BuildContext context) {
    final location = LocationPayload.fromJson(jsonDecode(message.content!));
    return MessageBubble(
      showNip: false,
      isCurrentUser: isCurrentUser,
      padding: const EdgeInsets.all(0),
      outerTimeAndStatusWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MessageDatetime(dateTime: message.createdAt),
          if (isCurrentUser) MessageStatusWidget(status: message.status),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 260,
          height: 180,
          child: InteractableDecoratedBox(
            onTap: () {
              var url =
                  'https://www.google.com/maps/place/@${location.latitude},${location.longitude},17z?hl=zh-CN';
              if (location.address?.isNotEmpty == true) {
                url =
                    'https://www.google.com/maps/search/${Uri.encodeComponent(location.address!)}/@${location.latitude},${location.longitude},17z?hl=zh-CN';
              }
              openUri(url);
            },
            child: Stack(
              children: [
                Map(
                  builder: (BuildContext context, int x, int y, int z) {
                    final url =
                        'https://www.google.com/maps/vt/pb=!1m4!1m3!1i$z!2i$x!3i$y!2m3!1e0!2sm!3i420120488!3m7!2sen!5e1105!12m4!1e68!2m2!1sset!2sRoadmap!4e0!5m1!1e0!23i4111425';
                    return CacheImage(url);
                  },
                  controller: MapController(
                    location: LatLng(22.927549869780467, 112.02908957855249),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.5),
                    child:
                        SvgPicture.asset(Resources.assetsImagesLocationMarkSvg),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}