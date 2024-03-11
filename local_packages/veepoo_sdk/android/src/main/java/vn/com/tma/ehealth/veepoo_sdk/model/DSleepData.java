package vn.com.tma.ehealth.veepoo_sdk.model;

import com.veepoo.protocol.model.datas.SleepData;
import com.veepoo.protocol.model.datas.SleepPrecisionData;

import lombok.Data;

@Data
public class DSleepData {
    private String date;
    private int sleepQuality;
    private int wakeCount;
    private String sleepLine;
    private String sleepDown;
    private String sleepUp;

    private int accurateType;
    private int deepScore;
    private int deepAndLightMode;
    private int fallAsleepScore;
    private int exitSleepMode;
    private int sleepEfficiencyScore;
    private int firstDeepDuration;
    private int getUpDuration;
    private int getUpScore;
    private int sleepTag;

    private int insomniaDuration;
    private int insomniaTag;
    private int insomniaLength;
    private int insomniaScore;
    private int insomniaTimes;

    public DSleepData(SleepData sleepData) {
        this.date = sleepData.getDate();
        this.sleepQuality = sleepData.getSleepQulity();
        this.wakeCount = sleepData.getWakeCount();
        this.sleepLine = sleepData.getSleepLine();
        this.sleepDown = sleepData.getSleepDown().getDateAndClockForSleepSecond();
        this.sleepUp = sleepData.getSleepUp().getDateAndClockForSleepSecond();
    }

    public DSleepData(SleepPrecisionData sleepData) {
        this.date = sleepData.getDate();
        this.sleepQuality = sleepData.getSleepQulity();
        this.wakeCount = sleepData.getWakeCount();
        this.sleepLine = sleepData.getSleepLine();
        this.sleepDown = sleepData.getSleepDown().getDateAndClockForSleepSecond();
        this.sleepUp = sleepData.getSleepUp().getDateAndClockForSleepSecond();

        this.accurateType = sleepData.getAccurateType();
        this.deepScore = sleepData.getDeepScore();
        this.fallAsleepScore = sleepData.getFallAsleepScore();
        this.exitSleepMode = sleepData.getExitSleepMode();
        this.sleepEfficiencyScore = sleepData.getSleepEfficiencyScore();
        this.firstDeepDuration = sleepData.getFirstDeepDuration();
        this.getUpDuration = sleepData.getGetUpDuration();
        this.getUpScore = sleepData.getGetUpScore();
        this.sleepTag = sleepData.getSleepTag();

        this.insomniaDuration = sleepData.getInsomniaDuration();
        this.insomniaTag = sleepData.getInsomniaTag();
        this.insomniaLength = sleepData.getInsomniaLength();
        this.insomniaTimes = sleepData.getInsomniaTimes();
        this.insomniaScore = sleepData.getInsomniaScore();
    }
}
