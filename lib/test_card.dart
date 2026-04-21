import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

void main() {
  CardSwiper(
    cardsCount: 2,
    cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
      return Container();
    },
    onSwipe: (previousIndex, currentIndex, direction) => true,
  );
}
