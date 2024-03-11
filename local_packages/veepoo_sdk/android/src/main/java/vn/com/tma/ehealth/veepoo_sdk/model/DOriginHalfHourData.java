package vn.com.tma.ehealth.veepoo_sdk.model;

import com.veepoo.protocol.model.datas.HalfHourBpData;
import com.veepoo.protocol.model.datas.HalfHourRateData;
import com.veepoo.protocol.model.datas.HalfHourSportData;
import com.veepoo.protocol.model.datas.OriginHalfHourData;

import java.util.List;

import lombok.Data;

@Data
public class DOriginHalfHourData {
    private int steps;
    private List<HalfHourSportData> halfHourSportData;
    private List<HalfHourRateData> halfHourRateData;
    private List<HalfHourBpData> halfHourBpData;

    public DOriginHalfHourData(OriginHalfHourData originHalfHourData) {
        this.steps = originHalfHourData.getAllStep();
        this.halfHourSportData = originHalfHourData.getHalfHourSportDatas();
        this.halfHourRateData = originHalfHourData.getHalfHourRateDatas();
        this.halfHourBpData = originHalfHourData.getHalfHourBps();
    }
}
