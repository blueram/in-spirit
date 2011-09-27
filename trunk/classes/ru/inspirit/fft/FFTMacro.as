package ru.inspirit.fft 
{
	import apparat.asm.__asm;
	import apparat.asm.__cint;
	import apparat.asm.IncLocalInt;
	import apparat.inline.Macro;
	import apparat.memory.Memory;
	
	/**
	 * FFT help routines
	 * @author Eugene Zatepyakin
	 */
	public final class FFTMacro extends Macro 
	{
		/**
		 * Radix-4 FFT butterfly
		 * transforms input inplace
		 * @param	in_re		real component
		 * @param	in_im		imag component
		 * @param	n			input length (power of 2)
		 * @param	l2n			log2 of input length
		 * @param	lut_ptr		mem offset to sin/cos lut table
		 */
		public static function doFFTR4(in_re:int, in_im:int, n:int, l2n:int, lut_ptr:int):void
		{
			var tmp0_re:Number, tmp0_im:Number, tmp1_re:Number, tmp1_im:Number;
			var tmp2_re:Number, tmp2_im:Number, tmp3_re:Number, tmp3_im:Number;
			var tmp00_re:Number, tmp00_im:Number, tmp01_re:Number, tmp01_im:Number;
			var tmp02_re:Number, tmp02_im:Number, tmp03_re:Number, tmp03_im:Number;
			var out0_re:Number, out0_im:Number, out1_re:Number, out1_im:Number;
			var out2_re:Number, out2_im:Number, out3_re:Number, out3_im:Number;
			var i:int, j:int;
			var off:int, off0:int;
			var iL:int, iB:int, le:int;
			var cs:Number, sn:Number;
			var iB8:int;
			
			var lp:int = lut_ptr;
			
			for (iL = 1; iL <= l2n; )
			{
				le = (1 << (iL << 1));
				iB = le >> 2; // Distance of the butterfly
				iB8 = iB << 3;
				for (j = 0; j < iB; )
				{
					// get sin/cos from lut table
					tmp1_re = Memory.readDouble(lp);
					tmp1_im = Memory.readDouble(__cint(lp+8));
					tmp2_re = Memory.readDouble(__cint(lp+16));
					tmp2_im = Memory.readDouble(__cint(lp+24));
					tmp3_re = Memory.readDouble(__cint(lp+32));
					tmp3_im = Memory.readDouble(__cint(lp+40));
					lp = __cint(lp + 48);
					
					for (i = j; i < n; )
					{
						off0 = off = __cint(i << 3);
						
						var re0:Number = Memory.readDouble(__cint(in_re + off));
						var im0:Number = Memory.readDouble(__cint(in_im + off));
						off = __cint(off + iB8);
						var re1:Number = Memory.readDouble(__cint(in_re + off));
						var im1:Number = Memory.readDouble(__cint(in_im + off));
						off = __cint(off + iB8);
						var re2:Number = Memory.readDouble(__cint(in_re + off));
						var im2:Number = Memory.readDouble(__cint(in_im + off));
						off = __cint(off + iB8);
						var re3:Number = Memory.readDouble(__cint(in_re + off));
						var im3:Number = Memory.readDouble(__cint(in_im + off));
						
						// multiply
						// skip first input since it is unchanged 
						out1_re = re1 * tmp1_re - im1 * tmp1_im;
						out1_im = re1 * tmp1_im + im1 * tmp1_re;
						
						out2_re = re2 * tmp2_re - im2 * tmp2_im;
						out2_im = re2 * tmp2_im + im2 * tmp2_re;
						
						out3_re = re3 * tmp3_re - im3 * tmp3_im;
						out3_im = re3 * tmp3_im + im3 * tmp3_re;
						
						FFTMacro.doDFT4(
										re0, im0, out1_re, out1_im,
										out2_re, out2_im, out3_re, out3_im,
										// temp vars
										tmp00_re, tmp00_im, tmp01_re, tmp01_im,
										tmp02_re, tmp02_im, tmp03_re, tmp03_im
										);
						// write result back
						Memory.writeDouble(re0, __cint(in_re + off0));
						Memory.writeDouble(im0, __cint(in_im + off0));
						off0 = __cint(off0 + iB8);
						Memory.writeDouble(out1_re, __cint(in_re + off0));
						Memory.writeDouble(out1_im, __cint(in_im + off0));
						off0 = __cint(off0 + iB8);
						Memory.writeDouble(out2_re, __cint(in_re + off0));
						Memory.writeDouble(out2_im, __cint(in_im + off0));
						off0 = __cint(off0 + iB8);
						Memory.writeDouble(out3_re, __cint(in_re + off0));
						Memory.writeDouble(out3_im, __cint(in_im + off0));
						//
						i = __cint(i + le);
					}
					//
					__asm(IncLocalInt(j));
				}
				//
				__asm(IncLocalInt(iL));
			}
		}
		
		/**
		 * Radix-2 FFT butterfly
		 * transforms input inplace
		 * @param	in_re		real component
		 * @param	in_im		imag component
		 * @param	n			input length (power of 2)
		 * @param	lut_ptr		mem offset to sin/cos lut table
		 */
		public static function doFFTL2(in_re:int, in_im:int, n:int, lut_ptr:int):void
		{
			var tmp0_re:Number, tmp0_im:Number;
			var out1_re:Number, out1_im:Number;
			var re0:Number, im0:Number, re1:Number, im1:Number;
			var off:int, off0:int;
			var iB:int = n >> 1;
			var iB8:int = iB << 3;
			
			var lp:int = lut_ptr;
			
			for (var i:int = 0; i < iB; )
			{
				tmp0_re = Memory.readDouble(lp);
				tmp0_im = Memory.readDouble(__cint(lp + 8));
				lp = __cint(lp + 16);
				//
				// read input
				off0 = off = i << 3;
				re0 = Memory.readDouble(__cint(in_re + off));
				im0 = Memory.readDouble(__cint(in_im + off));
				off = __cint(off + iB8);
				re1 = Memory.readDouble(__cint(in_re + off));
				im1 = Memory.readDouble(__cint(in_im + off));
				
				// mult
				// skip first input since it is unchanged 
				out1_re = re1 * tmp0_re - im1 * tmp0_im;
				out1_im = re1 * tmp0_im + im1 * tmp0_re;
				
				FFTMacro.doDFT2(re0, im0, out1_re, out1_im, tmp0_re, tmp0_im);
				
				// write result back
				Memory.writeDouble(re0, __cint(in_re + off0));
				Memory.writeDouble(im0, __cint(in_im + off0));
				off0 = __cint(off0 + iB8);
				Memory.writeDouble(out1_re, __cint(in_re + off0));
				Memory.writeDouble(out1_im, __cint(in_im + off0));
				//
				__asm(IncLocalInt(i));
			}
		}
		
		/**
		 * Find out if input is power of 4
		 * 
		 * @param	n		input integer to check
		 * @param	result	result 1/0 == true/false
		 * @param	mem		memory offset to perform read/write operation
		 */
		public static function isPowerOf4(n:int, result:int, mem:int):void
		{
			var log2n:int;
			FFTMacro.log2(n, log2n, mem);
			result = int( __cint((n&(n-1)|(log2n&1))) == 0 );
		}
		
		/**
		 * Magic (MAGIC) integer Base 2 logarithm method by Patrick Leclech :)
		 * @param	n		input integer
		 * @param	log2n	result output
		 * @param	mem		memory offset to perform read/write operation
		 */
		public static function log2(n:int, log2n:int, mem:int):void
		{
			Memory.writeDouble(n, mem);
			log2n = __cint((Memory.readInt(mem+4) >> 20) - 1023);
		}
		
		// Discrete fourier transformation of 2 points
		// need 1 temp var for re/im struct
		public static function doDFT2(
										rX0_re:Number, rX0_im:Number, 
										rX1_re:Number, rX1_im:Number,
										tmp_re:Number, tmp_im:Number):void
		{
			tmp_re = rX0_re; tmp_im = rX0_im;
			
			rX0_re = rX0_re + rX1_re;
			rX0_im = rX0_im + rX1_im;
			
			rX1_re = tmp_re - rX1_re;
			rX1_im = tmp_im - rX1_im;
		}
		
		// Discrete fourier transformation of 4 points
		// need 4 temp vars for re/im struct
		// TODO: possible arithmetic optimization?
		public static function doDFT4(
										rX0_re:Number, rX0_im:Number, 
										rX1_re:Number, rX1_im:Number,
										rX2_re:Number, rX2_im:Number,
										rX3_re:Number, rX3_im:Number,
										tmp0_re:Number, tmp0_im:Number,
										tmp1_re:Number, tmp1_im:Number,
										tmp2_re:Number, tmp2_im:Number,
										tmp3_re:Number, tmp3_im:Number):void
		{
			tmp0_re = rX0_re + rX1_re;
			tmp0_im = rX0_im + rX1_im;
			
			tmp1_re = rX0_re - rX1_re;
			tmp1_im = rX0_im - rX1_im;
			
			tmp2_re = rX2_re + rX3_re;
			tmp2_im = rX2_im + rX3_im;
			
			tmp3_re = rX2_im - rX3_im;
			tmp3_im = rX3_re - rX2_re;
			
			// the last stage
			rX0_re = tmp0_re + tmp2_re;
			rX0_im = tmp0_im + tmp2_im;
			
			rX1_re = tmp1_re + tmp3_re;
			rX1_im = tmp1_im + tmp3_im;
			
			rX2_re = tmp0_re - tmp2_re;
			rX2_im = tmp0_im - tmp2_im;
			
			rX3_re = tmp1_re - tmp3_re;
			rX3_im = tmp1_im - tmp3_im;
		}
		
	}

}