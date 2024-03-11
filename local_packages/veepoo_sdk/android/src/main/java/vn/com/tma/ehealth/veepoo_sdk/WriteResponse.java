package vn.com.tma.ehealth.veepoo_sdk;

import com.orhanobut.logger.Logger;
import com.veepoo.protocol.listener.base.IBleWriteResponse;

/**
 * Write status returned
 */
class WriteResponse implements IBleWriteResponse {
    private final static String TAG = WriteResponse.class.getSimpleName();

    @Override
    public void onResponse(int code) {
        Logger.t(TAG).i("write cmd status:" + code);

    }

}
