package logger

import "go.uber.org/zap"

var log *zap.Logger

func Init() {
	var err error
	log, err = zap.NewProduction()
	if err != nil {
		panic("failed to initialize zap logger: " + err.Error())
	}
}

func Info(msg string, fields ...zap.Field) {
	log.Info(msg, fields...)
}

func Error(msg string, fields ...zap.Field) {
	log.Error(msg, fields...)
}
