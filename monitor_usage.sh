#!/bin/bash

# Установите пороги использования ЦПУ и ГПУ.
# Set the CPU and GPU utilization thresholds.
CPU_THRESHOLD=10
GPU_THRESHOLD=10

# Счетчик, сколько раз подряд нагрузка была ниже порога
# Count how many times in a row the load has been below the threshold
LOW_USAGE_COUNT=0

while true; do
  # Получаем текущую загрузку ЦПУ.
  # Get the current CPU utilization.
  CPU_USAGE=$(mpstat 1 1 | awk '/Average/ {print 100 - $12}')
  # Преобразуем десятичный разделитель в точку, если он в формате запятой
  # Convert the decimal separator to a period if it is in comma format
  CPU_USAGE=$(LC_NUMERIC=C printf "%.0f\n" $CPU_USAGE)
  
  # Получаем текущую загрузку ГПУ (предполагая использование nvidia-smi для NVIDIA GPUs)
  # Get the current GPU utilization (assuming using nvidia-smi for NVIDIA GPUs)
  GPU_USAGE=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)

  # Проверяем, ниже ли загрузка пороговых значений.
  # Check if the download is below the thresholds.
  if [ $(echo "$CPU_USAGE < $CPU_THRESHOLD" | bc) -eq 1 ] && [ $(echo "$GPU_USAGE < $GPU_THRESHOLD" | bc) -eq 1 ]; then
    # Увеличиваем счетчик низкой нагрузки.
    # Increase the low load counter.
    ((LOW_USAGE_COUNT++))
  else
    # Если нагрузка выше порога, сбрасываем счетчик.
    # If the load is above the threshold, reset the counter.
    LOW_USAGE_COUNT=0
  fi

  # Если низкая нагрузка была обнаружена в течение 60 минут, останавливаем скрипт.
  # If low load was detected within 60 minutes, stop the script.
  if [ $LOW_USAGE_COUNT -ge 60 ]; then
    runpodctl stop pod ${RUNPOD_POD_ID}
    break
  fi

  # Пауза в одну минуту перед следующей итерацией.
  # A pause of one minute before the next iteration.
  sleep 60
done
