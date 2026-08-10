# src/weather.py
import requests
import random

def get_coastal_weather_risk(city="Mangaluru", api_key=None):
    """
    Evaluates fungal disease risk based on Coastal Karnataka weather conditions.
    """
    if api_key:
        try:
            url = f"http://api.openweathermap.org/data/2.5/weather?q={city},IN&appid={api_key}&units=metric"
            res = requests.get(url, timeout=3).json()
            humidity = res['main']['humidity']
            temp = res['main']['temp']
            rain = 'rain' in res
        except Exception:
            # Fallback to simulated data if network/key fails
            humidity, temp, rain = 88, 27.5, True
    else:
        # Simulated realistic Coastal Karnataka monsoon conditions
        humidity = random.randint(75, 95)
        temp = round(random.uniform(26.0, 31.0), 1)
        rain = humidity > 82

    high_risk = humidity > 80 or rain
    status = "HIGH FUNGAL RISK ⚠️" if high_risk else "MODERATE RISK 🌤️"
    
    advisory = (
        f"**Location:** {city}, Coastal Karnataka | **Temp:** {temp}°C | **Humidity:** {humidity}%\n\n"
        + ("🚨 **Warning:** High environmental humidity and rainfall create ideal breeding conditions for *Powdery Mildew* and *Leaf Curl* vectors. Preventive organic fungicide spraying is strongly recommended!" if high_risk 
           else "✅ Standard atmospheric moisture. Maintain normal field irrigation and monitoring.")
    )
    
    return {"status": status, "advisory": advisory, "high_risk": high_risk}