#!/bin/bash

# Установите пороги использования ЦПУ и ГПУ.
CPU_THRESHOLD=10
GPU_THRESHOLD=10

# Счетчик, сколько раз подряд нагрузка была ниже порога
LOW_USAGE_COUNT=0

while true; do
  # Получаем текущую загрузку ЦПУ.
  CPU_USAGE=$(mpstat 1 1 | awk '/Average/ {print 100 - $12}')
  # Преобразуем десятичный разделитель в точку, если он в формате запятой
  CPU_USAGE=$(LC_NUMERIC=C printf "%.0f\n" $CPU_USAGE)
  
  # Получаем текущую загрузку ГПУ (предполагая использование nvidia-smi для NVIDIA GPUs)
  GPU_USAGE=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)

  # Проверяем, ниже ли загрузка пороговых значений.
  if [ $(echo "$CPU_USAGE < $CPU_THRESHOLD" | bc) -eq 1 ] && [ $(echo "$GPU_USAGE < $GPU_THRESHOLD" | bc) -eq 1 ]; then
    # Увеличиваем счетчик низкой нагрузки.
    ((LOW_USAGE_COUNT++))
  else
    # Если нагрузка выше порога, сбрасываем счетчик.
    LOW_USAGE_COUNT=0
  fi

  # Если низкая нагрузка была обнаружена в течение 60 минут, останавливаем скрипт.
  if [ $LOW_USAGE_COUNT -ge 60 ]; then
    runpodctl stop pod ${RUNPOD_POD_ID}
    break
  fi

  # Пауза в одну минуту перед следующей итерацией.
  sleep 60
done