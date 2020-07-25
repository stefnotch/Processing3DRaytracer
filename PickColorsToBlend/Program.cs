using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.CompilerServices;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace PickColorsToBlend
{
    struct GreyscaleColor
    {
        public int Greyscale;
        public int Alpha;
    }

    struct ColorObject
    {
        public int BitPattern;
        public byte Depth;
    }

    class ColorsResult
    {
        public double Score { get; set; }
        public byte[] ResultingColors { get; set; }
        public ColorObject[] ResultingColorObjects { get; set; }
        public GreyscaleColor[] ColorLayers { get; set; }
    }

    class ColorsResultOutput
    {
        public ColorsResultOutput(ColorsResult colorsResult)
        {
            Score = colorsResult.Score;
            ResultingColorObjects = new FullColorObject[colorsResult.ResultingColorObjects.Length];
            for (int i = 0; i < ResultingColorObjects.Length; i++)
            {
                ResultingColorObjects[i] = new FullColorObject()
                {
                    ResultingColor = colorsResult.ResultingColors[i],
                    BitPattern = colorsResult.ResultingColorObjects[i].BitPattern,
                    Depth = colorsResult.ResultingColorObjects[i].Depth,
                };
            }
            ColorLayers = colorsResult.ColorLayers;
        }

        public class FullColorObject
        {
            public byte ResultingColor { get; set; }
            public int BitPattern { get; set; }
            public byte Depth { get; set; }
        }
        public double Score { get; set; }
        public FullColorObject[] ResultingColorObjects { get; set; }
        public GreyscaleColor[] ColorLayers { get; set; }
    }

    class Program
    {
        const int MAX_DEPTH = 5;
        const int RUNS = 1_000_000;

        static void Main(string[] args)
        {
            Console.WriteLine($"Runs {RUNS} with {MAX_DEPTH} color layers");
            int colorObjectCount = (int)Math.Pow(2, MAX_DEPTH);

            // This is the code that a thread haz to run:
            // The arrays are being created here to reduce the number of useless object allocations
            Stopwatch stopWatch = new Stopwatch();
            stopWatch.Start();
            byte[] resultingColors = new byte[colorObjectCount];
            ColorObject[] colorObjects = new ColorObject[colorObjectCount];

            GreyscaleColor[] colorLayers = new GreyscaleColor[MAX_DEPTH + 1];
            colorLayers[0] = new GreyscaleColor { Greyscale = 0, Alpha = 255 };
            colorLayers[1] = new GreyscaleColor { Greyscale = 255, Alpha = 255 };

            double maxScore = 0;
            ColorsResult maxResult = null;
            Random rng = new Random(); // This could be a source of derp, since the C# RNG != the Java RNG
            for (int i = 0; i < RUNS; i++)
            {
                ColorsResult result = DoRun(maxScore, resultingColors, colorObjects, colorLayers, rng);
                if (result != null)
                {
                    Console.WriteLine($"Best score {result.Score}");
                    maxScore = result.Score;
                    maxResult = result;
                }
            }
            stopWatch.Stop();
            Console.WriteLine($"Completed in {stopWatch.ElapsedMilliseconds}ms");

            Console.ReadLine();

            // And then output it or return it from the thread
            var jsonSerializerOptions = new JsonSerializerOptions
            {
                WriteIndented = true
            };
            jsonSerializerOptions.Converters.Add(new GreyscaleColorConverter());
            Console.WriteLine(JsonSerializer.Serialize(new ColorsResultOutput(maxResult), jsonSerializerOptions));
            Console.ReadLine();
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        static int ToggleBit(int number, int bitIndex)
        {
            return number ^ (1 << bitIndex);
        }

        static ColorsResult DoRun(double maxScore, byte[] resultingColors, ColorObject[] colorObjects, GreyscaleColor[] colorLayers, Random rng)
        {
            // 0th color object is always the black background
            // 1st color object is always the white foreground (layer 1)\
            // I have to do this every time because of the .Sort() at the end
            resultingColors[0] = 0;
            resultingColors[1] = 255;

            colorObjects[0] = new ColorObject() { BitPattern = 0, Depth = 0 };
            colorObjects[1] = new ColorObject() { BitPattern = ToggleBit(0, 1), Depth = 1 };

            int colorsObjectsLength = 2;

            // Now randomly choose the next color layers
            for (int depthIndex = 2; depthIndex < MAX_DEPTH + 1; depthIndex++)
            {
                // Choose color layer
                int greyscale = rng.Next(255);
                int alpha = rng.Next(255);
                colorLayers[depthIndex].Greyscale = greyscale;
                colorLayers[depthIndex].Alpha = alpha;

                // Copied from Processing's sauce code
                int s_a = alpha + (alpha >= 0x7F ? 1 : 0);
                int d_a = 0x100 - s_a;


                // Lerp it with all existing possibilities (colorObjects)
                int len = colorsObjectsLength;
                for (int j = 0; j < len; j++)
                {
                    // Copied from Processing's sauce code
                    int lerpedColor = (resultingColors[j] * d_a + greyscale * s_a) >> 8;

                    // New color object
                    resultingColors[colorsObjectsLength] = (byte)lerpedColor;
                    colorObjects[colorsObjectsLength].Depth = (byte)depthIndex;
                    colorObjects[colorsObjectsLength].BitPattern = ToggleBit(colorObjects[j].BitPattern, depthIndex);
                    colorsObjectsLength++;
                }
            }

            // And compute the score
            Array.Sort(resultingColors, colorObjects);
            double score = 0;
            for (int i = 0; i < colorsObjectsLength - 1; i++)
            {
                int diff = resultingColors[i + 1] - resultingColors[i];
                if (diff > 1)
                {
                    score += Math.Sqrt(diff);
                }
            }

            if (score <= maxScore)
            {
                return null;
            }
            else
            {
                return new ColorsResult()
                {
                    Score = score,
                    ResultingColors = (byte[])resultingColors.Clone(),
                    ResultingColorObjects = (ColorObject[])colorObjects.Clone(),
                    ColorLayers = (GreyscaleColor[])colorLayers.Clone()
                };
            }
        }
    }

    // Meh, a .NET Core 3 limitation with the Json converter. It can't handle fields, only properties.
    // It'll be fixed in .NET 5
    class GreyscaleColorConverter : JsonConverter<GreyscaleColor>
    {
        public override GreyscaleColor Read(
            ref Utf8JsonReader reader,
            Type typeToConvert,
            JsonSerializerOptions options) => throw new NotImplementedException();

        public override void Write(
            Utf8JsonWriter writer,
            GreyscaleColor value,
            JsonSerializerOptions options)
        {
            writer.WriteStartObject();
            writer.WriteNumber("Greyscale", value.Greyscale);
            writer.WriteNumber("Alpha", value.Alpha);
            writer.WriteEndObject();
        }
    }
}
