/*
 * Main activity for the BLE Sensor App
 * This activity displays a Connect button for the user.
 * When it is clicked, the activity searches for BLE devices and connects
 * to the first possible match for the Adafruit nRF8001 breakout board.
 * It then starts an activity for tracking sensor data from the rest of
 * the BLE Sensor project. This app has not been tested around multiple
 * Bluetooth enabled devices.
 *
 * Author: Graham Harvey
 * Last modified: 8 July 2014
 *
 * Parts of this code are very similar to the sample BluetoothLeGatt code on
 * the Android developer website.  See the following link:
 * https://developer.android.com/samples/BluetoothLeGatt/src/com.example.android.bluetoothlegatt/DeviceScanActivity.html
 *
 */

package gharvey.blesensorpack;

import android.app.Activity;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;


public class MainActivity extends Activity {
	
	private BluetoothAdapter btAdapter;
	private boolean scanning;
	private Handler bleHandler;
	
	private static final long SCAN_TIMEOUT = 3000; // timeout after 3 seconds

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
		
		// check if Bluetooth LE is supported on the device
		if(!getPackageManager().hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
			Toast.makeText(this, R.string.ble_not_supported, Toast.LENGTH_SHORT).show();
			finish();
		}
		
		// Initialize Bluetooth adapter
		final BluetoothManager btManager =
				(BluetoothManager) getSystemService(Context.BLUETOOTH_SERVICE);
		btAdapter = btManager.getAdapter();
		/* maybe
		btAdapter = BluetoothAdapter.getDefaultAdapter();
		*/
		
		// check if Bluetooth is supported on the device
		if(btAdapter == null) {
			Toast.makeText(this, R.string.error_bt_not_supported, Toast.LENGTH_SHORT.show();
			finish();
			return;
		}
		
//		ensureBtEn();
    }
	
	@Override
	protected void onResume() {
		super.onResume();
		
		ensureBtEn();
		btAdapter.startLeScan(bleScanCallback);
		//btAdapter.startLeScan(UUIDs, bleScanCallback);
	}
	
	@Override
	protected void onPause() {
		super.onPause();
		
		// stop scanning if needed
		scanning = false;
		btAdapter.stopLeScan(bleScanCallback);
	}
	
	@Override
	protected void onActivityResult(int reqCode, int resCode, Intent data_i) {
		// user did not enable Bluetooth
		if(reqCode == REQUEST_ENABLE_BT && resCode == Activity.RESULT_CANCELED) {
			finish();
			return;
		}
		super.onActivityResult(reqCode, resCode, data);
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
		// set up timeout
		bleHandler.postDelayed(new Runnable() {
			@Override
			public void run() {
				scanning = false;
				btAdapter.stopLeScan(bleScanCallback);
			}
		}, SCAN_TIMEOUT);
		
		scanning = true;
		btAdapter.startLeScan(bleScanCallback);
		//btAdapter.startLeScan(UUIDs, bleScanCallback);
	}

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.main, menu);
        return true;
    }

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
