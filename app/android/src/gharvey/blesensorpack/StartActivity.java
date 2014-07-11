/*
 * Start activity for the BLE Sensor App
 * This activity displays a Connect button for the user.
 * When it is clicked, the activity searches for BLE devices and connects
 * to the first possible match for the Adafruit nRF8001 breakout board.
 * It then starts an activity for tracking sensor data from the rest of
 * the BLE Sensor project. This app has not been tested around multiple
 * Bluetooth enabled devices.
 *
 * Author: Graham Harvey
 * Last modified: 9 July 2014
 *
 * Parts of this code are similar to the sample BluetoothLeGatt code on
 * the Android developer website.  The reference material that was used
 * is included in the project directory at doc/ref/BLE/Android.
 * 
 */

package gharvey.blesensorpack;

import java.util.UUID;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothAdapter.LeScanCallback;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.ParcelUuid;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.Toast;


public class StartActivity extends Activity {
	
	private BluetoothAdapter btAdapter;
	private boolean scanning;
	private Handler bleHandler;

	private static final String BLE_DEVICE_NAME = "BLE Sensor Pack";
	public static final int REQUEST_ENABLE_BT = 1;
	private static final long SCAN_TIMEOUT = 5000; // timeout in milliseconds
	
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_start);
                
        bleHandler = new Handler();
		
		// Initialize Bluetooth adapter
/*        final BluetoothManager btManager =
				(BluetoothManager) getSystemService(Context.BLUETOOTH_SERVICE);
		btAdapter = btManager.getAdapter();
*/
        btAdapter = BluetoothAdapter.getDefaultAdapter();
		
		// check if Bluetooth is supported on the device
		if(btAdapter == null) {
			Toast.makeText(this, R.string.error_bt_not_supported, Toast.LENGTH_SHORT).show();
			finish();
			return;
		}
		
		// check if Bluetooth LE is supported on the device
		if(!getPackageManager().hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
			Toast.makeText(this, R.string.error_ble_not_supported, Toast.LENGTH_SHORT).show();
			finish();
		}
		
		Log.d("onCreate()", "Setup complete");
    }
	
	@Override
	protected void onResume() {
		super.onResume();
		
		ensureBtEn();
		//btAdapter.startLeScan(bleScanCallback);
		//btAdapter.startLeScan(UUIDs, bleScanCallback);
	}
	
	@Override
	protected void onPause() {
		super.onPause();
		
		// stop scanning if needed
		if(scanning) {
			scanning = false;
			btAdapter.stopLeScan(bleScanCallback);
		}
	}
	
	@Override
	protected void onActivityResult(int reqCode, int resCode, Intent data_i) {
		// user did not enable Bluetooth
		if(reqCode == REQUEST_ENABLE_BT && resCode == Activity.RESULT_CANCELED) {
			finish();
			return;
		}
		super.onActivityResult(reqCode, resCode, data_i);
	}
	
	/*
	 * ensure that Bluetooth is available and enabled, or
	 * request permission to enable it
	 */
	protected void ensureBtEn() {
		if(!btAdapter.isEnabled()) {
			Intent btEnable_i = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
			startActivityForResult(btEnable_i, REQUEST_ENABLE_BT);
		}
	}
		
	/*
	 * Scan for available BLE devices and connect to the first one.
	 * Called when the user clicks the Connect button.
	 */
	public void bleScan(View view) {
		Log.v("bleScan()", "In bleScan()");
		// set up timeout
		bleHandler.postDelayed(new Runnable() {
			@Override
			public void run() {
				scanning = false;
				Log.v("bleScan()", "Stopping the scan");
				btAdapter.stopLeScan(bleScanCallback);
				
				// let the user know we couldn't find the device
				Toast.makeText(StartActivity.this, R.string.error_no_device, Toast.LENGTH_SHORT).show();
			}
		}, SCAN_TIMEOUT);

		
		// start the scan
		scanning = true;
		Log.v("bleScan()", "Starting the scan");
		btAdapter.startLeScan(bleScanCallback);
		Log.v("bleScan()", "Leaving bleScan()");
		//btAdapter.startLeScan(UUIDs, bleScanCallback);
	}
	
	private LeScanCallback bleScanCallback =
			new LeScanCallback() {
		@Override
		public void onLeScan(final BluetoothDevice bleDevice, int rssi,
							 byte[] scanRecord) {
			Log.d("bleScanCallback", "Device found.");
			
			// check if the device is the sensor pack
			if(isSensorPack(bleDevice)) {
				if(scanning) {
					btAdapter.stopLeScan(bleScanCallback);
					scanning = false;
				}
				
				// create an intent to interface with device
/*				Intent sensorInterface_i = new Intent(StartActivity.this, SensorInterfaceActivity.class);
				sensorInterface_i.putExtra(SensorInterfaceActivity.LABEL_DEVICE_NAME, bleDevice.getName());
				sensorInterface_i.putExtra(SensorInterfaceActivity.LABEL_DEVICE_ADDR, bleDevice.getAddress());
				
				startActivity(sensorInterface_i);
*/
			} else {
				Log.d("bleScanCallback", "Found wrong device");
			}
		}
	};
	
	// still need to implement this
	private boolean isSensorPack(BluetoothDevice btDevice) {
		Log.d("isSensorPack()", "Checking the device");
		if(!(btDevice.getName().contentEquals(BLE_DEVICE_NAME))) {
			Log.d("isSensorPack", "Device Name: " + btDevice.getName());
			return false;
		}
		// the device name is correct
		if(btDevice.fetchUuidsWithSdp()) {
			ParcelUuid[] supported_uuids = btDevice.getUuids();
			for(ParcelUuid pUuid : supported_uuids) {
				UUID uuid = pUuid.getUuid();
				Log.d("isSensorPack()", "Service UUID found: " + uuid.toString());
				if(uuid.equals(SensorInterfaceActivity.UART_UUID)) {
					// the device offers the UART service
					Log.d("isSensorPack()", "Found Sensor Pack!");
					return true;
				}
			}
		}
		
		return false;
	}

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.start, menu);
        return true;
    };

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();
        if (id == R.id.action_settings) {
            return true;
        }
        return super.onOptionsItemSelected(item);
    }
}
