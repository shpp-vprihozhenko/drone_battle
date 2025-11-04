import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'globals.dart';

class ZoomableImagePainter extends CustomPainter {
  final ui.Image image;
  final Offset offset;
  final double scale;
  List <Tank> tanks = [];
  List <Bomb> bombs = [];

  ZoomableImagePainter(this.image, this.offset, this.scale, this.tanks, this.bombs);

  _drawBombs(canvas){
    for (var bomb in bombs) {
      Offset position = bomb.targetPoint + offset - Offset(14, bomb.height);
      double scale = bomb.height/glBaseBombHeight*0.64;
      if (bomb.boomTimer > 0) {
        scale = 1-bomb.boomTimer / glBombBoomTime;
      }
      //printD('draw bomb at $position with scale $scale offset $offset');
      ui.Image bImg = bomb.boomTimer>0? uiBoom! :
        bomb.isExtra? uiBomb2! : uiBomb!
      ;
      Size imgSize = Size(bImg.width*scale, bImg.height*scale);
      if (bomb.boomTimer>0) {
        position -= Offset(imgSize.width/2-5, imgSize.height/2+33);
      }
      paintImage(
        canvas: canvas,
        rect: position & imgSize,
        image: bImg,
        fit: BoxFit.fill,
        //scale: scale,
        //colorFilter: ColorFilter.srgbToLinearGamma()
      );
    }

    /*
    for (int idx=0; idx< dbs.length; idx++) {
      Offset db = dbs[idx];
      double dx = db.dx+offset.dx;
      double dy = db.dy+offset.dy;
      Offset co = Offset(dx, dy);
      canvas.drawCircle(co, 10, p);
      printD('draw circle No $idx at ${dx.toInt()}/${dy.toInt()} db ${db.dx.toInt()}/${db.dy.toInt()} offset ${offset.dx.toInt()}/${offset.dy.toInt()}');
    }
   */

  }

  _drawBombMarker(canvas, canvasSize){
    Offset tp = Offset(canvasSize.width/2-8, canvasSize.height/3*2-33) ;
    glMapDronePos = Offset(canvasSize.width/2-offset.dx, canvasSize.height/3*2-offset.dy);

    Paint p = Paint(); p.color = Colors.redAccent; p.strokeWidth = 5;
    canvas.drawLine(Offset(tp.dx-10, tp.dy), Offset(tp.dx+10, tp.dy), p);
    canvas.drawLine(Offset(tp.dx, tp.dy-10), Offset(tp.dx, tp.dy+10), p);
  }

  _tryDrawTankMarker(Tank tank, Canvas canvas, canvasSize){
    if (tank.isDamaged) {
      return;
    }
    Offset delta = tank.mapPos - glMapDronePos;
    double distance = delta.distance;
    if (distance > glDroneRadarRadius) {
      return;
    }
    double markerRadius = 30 * (1-distance/glDroneRadarRadius);

    Paint p = Paint(); p.color = Colors.blue; p.strokeWidth = 6;

    //printD('tid ${tank.id} mapPos ${tank.mapPos} glMapDronePos $glMapDronePos delta $delta');
    double dx1 = delta.dx;
    double dy1 = delta.dy;
    double dx3 = canvasSize.width/2;
    double dy3 = -canvasSize.height/3*2;
    double dy4 = canvasSize.height + dy3;

    double tn = dx1/dy1;

    double dx2 = dx1 > 0? dx3 : -dx3;
    double dy2 = dx2 / tn;

    if (dy1 > 0) {
      if (dy2 > dy4) {
        dy2 = dy4;
        dx2 = dy2 * tn;
      }
    } else {
      if (dy2 < dy3) {
        dy2 = dy3;
        dx2 = dy2 * tn;
      }
    }
    Offset canvasMarkerPos = Offset(dx2, dy2) + glMapDronePos + offset;
    canvas.drawCircle(canvasMarkerPos, markerRadius, p);
  }

  _drawTanks(Canvas canvas, canvasSize){
    Paint p = Paint(); p.color = Colors.blue; p.strokeWidth = 5;
    for (var tank in tanks) {
      ui.Image uiTank = tank.uiImg!;

      Offset tankOffset = offset + Offset(tank.x*scale, tank.y*scale) - Offset(uiTank.width/2, uiTank.height/2);
      Size tankSize = Size(tank.width.toDouble(), tank.height.toDouble());
      tank.mapPos = Offset(tank.x*scale, tank.y*scale) - Offset(uiTank.width/2, uiTank.height/2);

      if (tankOffset.dx+tank.width.toDouble() < 0 || tankOffset.dy+tank.height.toDouble() < 0 ||
          tankOffset.dx > canvasSize.width || tankOffset.dy > canvasSize.height) {
        tank.isOnCanvas = false;
        tank.gunStage = 0;
        _tryDrawTankMarker(tank, canvas, canvasSize);
        continue;
      }
      tank.isOnCanvas = true;
      tank.canvasPos = tankOffset+Offset(uiTank.width/2, uiTank.height/2);
      //print('tankOffset $tank is $tankOffset');

      paintImage(
          canvas: canvas,
          rect: tankOffset & tankSize,
          image: uiTank, // tankImg
          fit: BoxFit.fill,
          colorFilter: tank.isDamaged? const ColorFilter.srgbToLinearGamma() : null
      );

      TextSpan span = TextSpan(
          style: const TextStyle(color: Colors.black),
          text: tank.id.toString()
      );
      TextPainter tp =  TextPainter(text: span,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr
      );
      tp.layout();
      tp.paint(canvas, tankOffset+tank.forehead);

      //Offset midPoint = offset + Offset(tank.x*scale, tank.y*scale) - Offset(10*cos(tank.direction*kpi), 10*sin(tank.direction*kpi));
      //canvas.drawCircle(midPoint, 6, p);
    }
  }

  _drawTankGunFire(Canvas canvas){
    Paint p = Paint(); p.color = Colors.white; p.strokeWidth = 4;
    for (var tank in tanks) {
      if (!tank.isOnCanvas) {
        continue;
      }
      if (tank.isDamaged) {
        continue;
      }
      if (tank.canvasPos.dy < 200) {
        continue;
      }
      tank.gunStage+=3;
      if (tank.id != -1) {
        double dx = tank.canvasPos.dx - gl2dDronePos.dx;
        double dy = tank.canvasPos.dy - gl2dDronePos.dy;
        double gip = sqrt(dx*dx+dy*dy);
        double angleX = dx/gip;
        double angleY = dy/gip;
        Offset pos1 = Offset(tank.canvasPos.dx - tank.gunStage*angleX,
            tank.canvasPos.dy - tank.gunStage*angleY);
        Offset pos2 = Offset(tank.canvasPos.dx - (tank.gunStage+10)*angleX,
            tank.canvasPos.dy - (tank.gunStage+10)*angleY);
        canvas.drawLine(pos1, pos2, p);
        if ((pos2-gl2dDronePos).distance<80) {
          canvas.drawCircle(pos2, 10, p);
          if ((pos2-gl2dDronePos).distance<70) {
            tank.gunStage = 0;
            glDroneLife -= 5;
            if (glDroneLife < 0) {
              glDroneLife = 0;
            }
          }
        }
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) async {
    Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
    Size targetSize = imageSize * scale;

    paintImage(
      canvas: canvas,
      rect: offset & targetSize,
      image: image,
      fit: BoxFit.fill,
    );

    _drawTanks(canvas, size);
    _drawTankGunFire(canvas);
    _drawBombMarker(canvas, size);
    _drawBombs(canvas);

    //canvas.drawCircle(gl2dDronePos, 5, p);

  }

  @override
  bool shouldRepaint(ZoomableImagePainter oldDelegate) {
    //return old.image != image || old.offset != offset || old.scale != scale;
    return true;
  }

}
