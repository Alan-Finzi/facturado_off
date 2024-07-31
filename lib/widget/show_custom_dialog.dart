import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<dynamic> showCustomDialog(BuildContext context, String title,
    String content, String defaultActionText,
    {String? cancelActionText,
        Function? defaultAction,
        Function? defaultCancel}) async {
    if (!Platform.isIOS) {
        return showDialog(
            context: context,
            builder: (context) => AlertDialog(
                title: Text(
                    title,
                    textScaleFactor: 1.0,
                ),
                content: Text(
                    content,
                    textScaleFactor: 1.0,
                ),
                actions: <Widget>[
                    if (cancelActionText != null)
                        TextButton(
                            onPressed: () {
                                if (defaultCancel != null) {
                                    defaultCancel();
                                }
                                Navigator.of(context).pop(false);
                            },
                            child: Text(cancelActionText)),
                    TextButton(
                        child: Text(
                            defaultActionText,
                            textScaleFactor: 1.0,
                        ),
                        onPressed: () {
                            Navigator.of(context).pop(true);
                            if (defaultAction != null) {
                                defaultAction();
                            }
                        },
                    ),
                ],
            ),
        );
    }

    // ToDO : showDialog for ios
    return showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
            title: Text(
                title,
                textScaleFactor: 1.0,
            ),
            content: Text(
                content,
                textScaleFactor: 1.0,
            ),
            actions: <Widget>[
                if (cancelActionText != null)
                    CupertinoDialogAction(
                        child: Text(
                            cancelActionText,
                            textScaleFactor: 1.0,
                        ),
                        onPressed: () {
                            if (defaultCancel != null) {
                                defaultCancel();
                            }
                            Navigator.of(context).pop(false);
                        },
                    ),
                CupertinoDialogAction(
                    child: Text(defaultActionText),
                    onPressed: () {
                        Navigator.of(context).pop(true);
                        if (defaultAction != null) {
                            defaultAction();
                        }
                    },
                ),
            ],
        ),
    );
}
