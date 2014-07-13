package gharvey.blesensorpack;

public class Sensor {
	private String name;
	private Float data;
	private String units;
	private boolean enable;
	protected int id_bit;
	
	public Sensor(String name, String units, int id_bit) {
		this.name = name;
		this.data = null;
		this.units = units;
		this.enable = false;
		this.id_bit = id_bit;
	}
	
	public void setName(String name) {
		this.name = name;
	}
	
	public String getName() {
		return this.name;
	}
	
	public float getData() {
		if(this.data != null) {
			return this.data.floatValue();
		} else {
			return Float.valueOf(Float.NaN);
		}
	}
	
	public void setData(float value) {
		this.data = Float.valueOf(value);
	}
	

	public boolean hasData() {
		return (this.data != null);
	}

	
	public void setUnits(String units) {
		this.units = units;
	}
	
	public String getUnits() {
		return this.units;
	}
	
	public void turnOn() {
		this.enable = true;
	}
	
	public void turnOff() {
		this.enable = false;
	}
	
	public boolean isOn() {
		return this.enable;
	}
	
	public void toggle() {
		if(this.isOn()) {
			this.turnOff();
		} else {
			this.turnOn();
		}
	}
}